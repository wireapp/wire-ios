//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import XCTest
import WireMockTransport
import WireTransport

@testable import WireSyncEngine

final class SearchTaskTests: DatabaseTest {

    var teamIdentifier: UUID!

    private var mockTransportSession: MockTransportSession!
    private var mockCache: SearchUsersCache!

    override func setUp() {
        super.setUp()

        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)
        mockCache = SearchUsersCache()
        teamIdentifier = UUID()

        performPretendingUIMocIsSyncMoc { [unowned self] in
            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.remoteIdentifier = UUID()
            selfUser.teamIdentifier = teamIdentifier
            let team = Team.fetchOrCreate(
                with: teamIdentifier,
                in: uiMOC
            )
            _ = Member.getOrUpdateMember(for: selfUser, in: team, context: uiMOC)
            uiMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        teamIdentifier = nil
        mockTransportSession = nil
        mockCache = nil

        super.tearDown()
    }

    private func createConnectedUser(withName name: String, domain: String? = nil) async throws -> ZMUser {
        try await uiMOC.perform { [uiMOC] in
            let user = ZMUser.insertNewObject(in: uiMOC)
            user.name = name
            user.remoteIdentifier = UUID.create()
            user.domain = domain

            let connection = ZMConnection.insertNewObject(in: uiMOC)
            connection.to = user
            connection.status = .accepted

            try uiMOC.save()

            return user
        }
    }

    private func createGroupConversation(withName name: String) async throws -> ZMConversation {
        try await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.name = "Me"
            conversation.userDefinedName = name
            conversation.conversationType = .group
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            try uiMOC.save()

            return conversation
        }
    }

    // MARK: -

    func testThatItFindsASingleUnconnectedUserByHandle() async throws {

        // given
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockUser = remoteChanges.insertUser(withName: "Dale Cooper")
            mockUser.handle = "bob"
        }

        let request = SearchRequest(query: "bob", searchOptions: [.directory])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearchForTeamUser()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.count, 1)
        let user = result.directory.first
        XCTAssertEqual(user?.name, "Dale Cooper")
        XCTAssertEqual(user?.handle, "bob")

    }

    func testThatItReturnsNothingWhenSearchingForSelfUserByHandle() async throws {

        // given
        var selfUserID: UUID!

        // create self user remotely
        mockTransportSession.performRemoteChanges { remoteChanges in
            let selfUser = remoteChanges.insertSelfUser(withName: "albert")
            selfUser.handle = "einstein"
            selfUserID = UUID(uuidString: selfUser.identifier)!
        }

        // update self user locally
        try await syncMOC.perform { [syncMOC] in
            ZMUser.selfUser(in: syncMOC).remoteIdentifier = selfUserID
            try syncMOC.save()
        }

        let request = SearchRequest(query: "einstein", searchOptions: [.directory])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearchForTeamUser()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.count, 0)
    }

    // MARK: Contacts Search

    func testThatItFindsASingleUser() async throws {

        // given
        let user = try await createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "userA", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    func testThatItDoesFindUsersContainingButNotBeginningWithSearchString() async throws {
        // given
        _ = try await createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "serA", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.count, 1)
    }

    func testThatItFindsUsersBeginningWithSearchString() async throws {
        // given
        let user = try await createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    func testThatItUsesAllQueryComponentsToFindAUser() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Some Body")
        _ = try await createConnectedUser(withName: "Some")
        _ = try await createConnectedUser(withName: "Any Body")

        let request = SearchRequest(query: "Some Body", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
    }

    func testThatItFindsSeveralUsers() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Grant")
        let user2 = try await createConnectedUser(withName: "Greg")
        _ = try await createConnectedUser(withName: "Bob")

        let request = SearchRequest(query: "Gr", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user1, user2])
    }

    func testThatUserSearchIsCaseInsensitive() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
    }

    func testThatUserSearchIsInsensitiveToDiacritics() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
    }

    func testThatUserSearchOnlyReturnsConnectedUsers() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Somebody Blocked")
        await uiMOC.perform {
            user1.connection?.status = .blocked
        }
        let user2 = try await createConnectedUser(withName: "Somebody Pending")
        await uiMOC.perform {
            user2.connection?.status = .pending
        }
        let user3 = try await createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "Some", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
    }

    func testThatItDoesNotReturnTheSelfUser() async throws {
        // given
        await uiMOC.perform { [self] in
            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.name = "Some self user"
        }
            let user = try await createConnectedUser(withName: "Somebody")

            let request = SearchRequest(query: "Some", searchOptions: [.contacts])
            let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.compactMap(\.user), [user])
    }

    func testThatItDoesNotFindUsersWithOtherDomainsIfSearchDomainIsRequired() async throws {
        // given
        _ = try await createConnectedUser(withName: "userA", domain: "bella.com")

        let request = SearchRequest(query: "userA@bella.com", searchDomain: "anta.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.contacts.count, 0)
    }

    func testThatItFindsUsersWithSameDomainAsSelfUser() async throws {
        // given
        let user = try await createConnectedUser(withName: "userA", domain: "anta.com")

        let request = SearchRequest(query: "userA@anta.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    func testThatItFindsUsersWithOtherDomainsIfSearchDomainIsNotRequired() async throws {
        // given
        let user = try await createConnectedUser(withName: "userA", domain: "bella.com")

        let request = SearchRequest(query: "userA@bella.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    // MARK: Team member local search

    func testThatItCanSearchForTeamMembersLocally() async throws {
        let (user, task) = await uiMOC.perform { [self] in
            // given
            let team = Team.insertNewObject(in: uiMOC)
            let user = ZMUser.insertNewObject(in: uiMOC)
            let member = Member.insertNewObject(in: uiMOC)
            
            user.name = "Member A"
            
            member.team = team
            member.user = user
            
            uiMOC.saveOrRollback()
            
            let request = SearchRequest(query: "@member", searchOptions: [.teamMembers], team: team)
            let task = makeSearchTask(request: request)
            return (user, task)
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [user])
    }

    func testThatItCanExcludeNonActiveTeamMembersLocally() async throws {
        let (userA, task) = await uiMOC.perform { [self] in
            // given
            let team = Team.insertNewObject(in: uiMOC)
            let userA = ZMUser.insertNewObject(in: uiMOC)
            let userB = ZMUser.insertNewObject(in: uiMOC)
            let memberA = Member.insertNewObject(in: uiMOC)
            let memberB = Member.insertNewObject(in: uiMOC) // non-active team-member
            let conversation = ZMConversation.insertNewObject(in: uiMOC)

            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID()
            conversation.addParticipantsAndUpdateConversationState(
                users: Set([userA, ZMUser.selfUser(in: uiMOC)]),
                role: nil
            )

            userA.name = "Member A"
            userB.name = "Member B"

            memberA.team = team
            memberA.user = userA

            memberB.team = team
            memberB.user = userB

            uiMOC.saveOrRollback()

            let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActiveTeamMembers], team: team)
            let task = makeSearchTask(request: request)
            return (userA, task)
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
    }

    func testThatItIncludesNonActiveTeamMembersLocally_WhenSelfUserWasCreatedByThem() async throws {
        let (userA, task) = await uiMOC.perform { [self] in
            // given
            let team = Team.insertNewObject(in: uiMOC)
            let userA = ZMUser.insertNewObject(in: uiMOC)
            let memberA = Member.insertNewObject(in: uiMOC) // non-active team-member
            let selfUser = ZMUser.selfUser(in: uiMOC)

            userA.name = "Member A"
            userA.handle = "abc"

            selfUser.membership?.permissions = .partner
            selfUser.membership?.createdBy = userA

            memberA.team = team
            memberA.user = userA
            memberA.permissions = .admin

            uiMOC.saveOrRollback()

            let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActiveTeamMembers], team: team)
            let task = makeSearchTask(request: request)
            return (userA, task)
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
    }

    func testThatItCanExcludeNonActivePartnersLocally() async throws {
        let (userA, userB, task) = try await uiMOC.perform { [self] in
            // given
            let team = Team.insertNewObject(in: uiMOC)
            let userA = ZMUser.insertNewObject(in: uiMOC)
            let userB = ZMUser.insertNewObject(in: uiMOC)
            let userC = ZMUser.insertNewObject(in: uiMOC)
            let memberA = Member.insertNewObject(in: uiMOC)
            let memberB = Member.insertNewObject(in: uiMOC) // active partner
            let memberC = Member.insertNewObject(in: uiMOC) // non-active partner
            let conversation = ZMConversation.insertNewObject(in: uiMOC)

            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID()
            conversation.addParticipantsAndUpdateConversationState(
                users: Set([userA, userB, ZMUser.selfUser(in: uiMOC)]),
                role: nil
            )

            userA.name = "Member A"
            userB.name = "Member B"
            userC.name = "Member C"

            memberA.team = team
            memberA.user = userA
            memberA.permissions = .member

            memberB.team = team
            memberB.user = userB
            memberB.permissions = .partner

            memberC.team = team
            memberC.user = userC
            memberC.permissions = .partner

            try uiMOC.save()

            let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
            let task = makeSearchTask(request: request)
            return (userA, userB, task)
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA, userB])
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSearchingWithExactHandle() async throws {
        let (userA, task) = await uiMOC.perform { [self] in
            // given
            let team = Team.insertNewObject(in: uiMOC)
            let userA = ZMUser.insertNewObject(in: uiMOC)
            let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

            userA.name = "Member A"
            userA.handle = "abc"

            memberA.team = team
            memberA.user = userA
            memberA.permissions = .partner

            uiMOC.saveOrRollback()

            let searchOptions: SearchOptions = [.teamMembers, .excludeNonActivePartners]
            let request = SearchRequest(query: "@abc", searchOptions: searchOptions, team: team)
            let task = makeSearchTask(request: request)
            return (userA, task)
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSelfUserCreatedPartner() async throws {
        let (userA, team) = try await uiMOC.perform { [uiMOC] in
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

        userA.name = "Member A"
        userA.handle = "abc"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .partner
        memberA.createdBy = ZMUser.selfUser(in: uiMOC)

        try uiMOC.save()

            return (userA, team)
    }

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
    }

    // MARK: Conversation Search

    func testThatItFindsASingleConversation() async throws {
        // given
        let conversation = try await createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "Somebody", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation])
    }

    func testThatItDoesFindConversationsUsingPartialNames() async throws {
        // given
        let conversation = try await createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "mebo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation])
    }

    func testThatItFindsSeveralConversations() async throws {
        // given
        let conversation1 = try await createGroupConversation(withName: "Candy Apple Records")
        let conversation2 = try await createGroupConversation(withName: "Landspeed Records")
        _ = try await createGroupConversation(withName: "New Day Rising")

        let request = SearchRequest(query: "Records", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation1, conversation2])
    }

    func testThatConversationSearchIsCaseInsensitive() async throws {
        // given
        let conversation = try await createGroupConversation(withName: "SoMEBody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }
        
        // then
        XCTAssertEqual(result.conversations, [conversation])
    }

    func testThatConversationSearchIsInsensitiveToDiacritics() async throws {
        // given
        let conversation = try await createGroupConversation(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation])
    }

    func testThatItOnlyFindsGroupConversations() async throws {
        // given
        let groupConversation = try await createGroupConversation(withName: "Group Conversation")
        let oneOnOneConversation = try await createGroupConversation(withName: "OneOnOne Conversation")
        await uiMOC.perform {
            oneOnOneConversation.conversationType = .oneOnOne
        }
        let selfConversation = try await createGroupConversation(withName: "Self Conversation")

        try await uiMOC.perform { [uiMOC] in
            selfConversation.conversationType = .self
            try uiMOC.save()
        }

        let request = SearchRequest(query: "Conversation", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [groupConversation])
    }

    func testThatItFindsConversationsThatDoNotHaveAUserDefinedName() async throws {
        // given
        let conversation = await uiMOC.perform { [uiMOC] in
            let conversation = ZMConversation.insertNewObject(in: uiMOC)
            conversation.conversationType = .group
            return conversation
        }

        let user1 = try await createConnectedUser(withName: "Shinji")
        let user2 = try await createConnectedUser(withName: "Asuka")
        let user3 = try await createConnectedUser(withName: "Rëï")

        try await uiMOC.perform { [uiMOC] in
            conversation.addParticipantsAndUpdateConversationState(users: [user1, user2, user3], role: nil)
            try uiMOC.save()
        }

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations, .contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation])
        XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
    }

    func testThatItFindsConversationsThatContainsSearchTermOnlyInParticipantName() async throws {
        // given
        let conversation = try await createGroupConversation(withName: "Summertime")
        let user = try await createConnectedUser(withName: "Rëï")
        try await uiMOC.perform { [uiMOC] in
            conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
            try uiMOC.save()
        }

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation])
    }

    func testThatItOrdersConversationsByUserDefinedName() async throws {
        // given
        let conversation1 = try await createGroupConversation(withName: "FooA")
        let conversation2 = try await createGroupConversation(withName: "FooC")
        let conversation3 = try await createGroupConversation(withName: "FooB")

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation2])
    }

    func testThatItOrdersConversationsByUserDefinedNameFirstAndByParticipantNameSecond() async throws {
        // given
        let user1 = try await createConnectedUser(withName: "Bla")
        let user2 = try await createConnectedUser(withName: "FooB")

        let conversation1 = try await createGroupConversation(withName: "FooA")
        let conversation2 = try await createGroupConversation(withName: "Bar")
        let conversation3 = try await createGroupConversation(withName: "FooB")
        let conversation4 = try await createGroupConversation(withName: "Bar")

        try await uiMOC.perform { [uiMOC] in
            conversation2.addParticipantAndUpdateConversationState(user: user1, role: nil)
            conversation4.addParticipantsAndUpdateConversationState(users: [user1, user2], role: nil)
            
            try uiMOC.save()
        }

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation4])
    }

    func testThatItFiltersConversationWhenTheQueryStartsWithAtSymbol() async throws {
        // given
        _ = try await createGroupConversation(withName: "New Day Rising")
        _ = try await createGroupConversation(withName: "Landspeed Records")

        let request = SearchRequest(query: "@records", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(result.conversations, [])
    }

    func testThatItReturnsAllConversationsWhenPassingTeamParameter() async throws {
        // given
        let team = await uiMOC.perform { [uiMOC] in
            Team.insertNewObject(in: uiMOC)
        }
        let conversationInTeam = try await createGroupConversation(withName: "Beach Club")
        let conversationNotInTeam = try await createGroupConversation(withName: "Beach Club")

        try await uiMOC.perform { [uiMOC] in
            conversationInTeam.team = team
            try uiMOC.save()
        }

        let request = SearchRequest(query: "Beach", searchOptions: [.conversations], team: team)
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        await uiMOC.perform {
            resultAggregator(&result)
        }

        // then
        XCTAssertEqual(Set(result.conversations), Set([conversationInTeam, conversationNotInTeam]))
    }

    // MARK: Directory Search

    func testThatItSendsASearchRequest() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/search/contacts?q=steve%20o'hara%20%26%20s%C3%B6hne&size=10"
        )
    }

    func testThatItDoesNotSendASearchRequestIfSeachingLocally() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 0)
    }

    func testThatItDoesNotSendASearchRequestIfLocalResultsOnly() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.directory, .localResultsOnly])
        let task = makeSearchTask(request: request)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 0)
    }

    func testThatItEncodesAPlusCharacterInTheSearchURL() async throws {
        // given
        let request = SearchRequest(query: "foo+bar@example.com", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/search/contacts?q=foo%2Bbar&domain=example.com&size=10"
        )
    }

    func testThatItEncodesUnsafeCharactersInRequest() async throws {
        // RFC 3986 Section 3.4 "Query"
        // <https://tools.ietf.org/html/rfc3986#section-3.4>
        //
        // "The characters slash ("/") and question mark ("?") may represent data within the query component."

        // given
        let request = SearchRequest(query: "$&+,/:;=?@", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/search/contacts?q=$%26%2B,/:;%3D?&size=10"
        )
    }

    func testThatItCallsCompletionHandlerForDirectorySearch() async throws {
        // given
        let request = SearchRequest(query: "User", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "User A")
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearch()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.first?.name, "User A")
    }

    // MARK: Directory Search - Membership lookup

    func testThatItMakesRequestToFetchTeamMembershipMetadata() async throws {
        // given
        let request = SearchRequest(query: "User", searchOptions: [.directory, .teamMembers])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        mockTransportSession.performRemoteChanges { remoteChanges in
            let userA = remoteChanges.insertUser(withName: "User A")
            let team = remoteChanges.insertTeam(withName: "Team A", isBound: true)
            team.identifier = self.teamIdentifier.transportString()
            team.creator = userA
            remoteChanges.insertMember(with: userA, in: team)
        }

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 2)
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/v2/search/contacts?q=user&size=10")
        XCTAssertEqual(
            mockTransportSession.receivedRequests().last?.path,
            "/v2/teams/\(teamIdentifier.transportString())/get-members-by-ids-using-post"
        )
    }

    func testThatItDoesNotMakeRequestToFetchTeamMembershipMetadata_WhenLocalResultsOnly() async throws {
        // given
        let request = SearchRequest(query: "User", searchOptions: [.directory, .teamMembers, .localResultsOnly])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        mockTransportSession.performRemoteChanges { remoteChanges in
            let userA = remoteChanges.insertUser(withName: "User A")
            let team = remoteChanges.insertTeam(withName: "Team A", isBound: true)
            team.identifier = self.teamIdentifier.transportString()
            team.creator = userA
            remoteChanges.insertMember(with: userA, in: team)
        }

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItCallsCompletionHandlerForTeamMemberDirectorySearch() async throws {
        // given
        let request = SearchRequest(query: "User", searchOptions: [.directory, .teamMembers])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        mockTransportSession.performRemoteChanges { remoteChanges in
            let userA = remoteChanges.insertUser(withName: "User A")
            let selfUser = remoteChanges.insertSelfUser(withName: "Self User")
            let team = remoteChanges.insertTeam(withName: "Team A", isBound: true)
            team.identifier = self.teamIdentifier.transportString()
            team.creator = userA
            remoteChanges.insertMember(with: selfUser, in: team)
            let member = remoteChanges.insertMember(with: userA, in: team)
            member.permissions = .admin
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearch()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.teamMembers.first?.name, "User A")
        XCTAssertEqual(result.teamMembers.first?.teamRole, .admin)
    }

    // MARK: Services search

    func testThatItSendsASearchServicesRequest() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.services])
        let task = makeSearchTask(request: request)

        // when
        _ = await task.performRemoteSearchForServices()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 1))
        // wait again to fix flaky test so second group is entered
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 1))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/teams/\(teamIdentifier.transportString())/services/whitelisted?prefix=steve%20o'hara%20%26%20s%C3%B6hne"
        )
    }

    func testThatItDoesNotSendASearchServicesRequest_WhenLocalResultsOnly() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.services, .localResultsOnly])
        let task = makeSearchTask(request: request)

        // when
     _ = await task.performRemoteSearchForServices()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItCallsCompletionHandlerForServicesSearch() async throws {
        // given
        let request = SearchRequest(query: "Service", searchOptions: [.services])
        let task = makeSearchTask(request: request)

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertService(
                withName: "Service A",
                identifier: UUID().transportString(),
                provider: UUID().transportString()
            )
        }

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearchForServices()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.services.first?.name, "Service A")
    }

    func testThatItTrimsThePrefixQuery() throws {
        // when
        let task = SearchTask.servicesSearchRequest(
            teamIdentifier: teamIdentifier,
            query: "Search query ",
            apiVersion: .v0
        )
        // then
        let components = URLComponents(url: task.URL, resolvingAgainstBaseURL: false)

        XCTAssertEqual(components?.queryItems?.count, 1)
        let queryItem = components?.queryItems?.first
        XCTAssertEqual(queryItem?.name, "prefix")
        XCTAssertEqual(queryItem?.value, "Search query")
    }

    func testThatItDoesNotAddPrefixQueryIfItIsEmpty() {
        // when
        let task = SearchTask.servicesSearchRequest(teamIdentifier: teamIdentifier, query: "", apiVersion: .v0)
        // then
        let components = URLComponents(url: task.URL, resolvingAgainstBaseURL: false)

        XCTAssertNil(components?.queryItems)
    }

    // MARK: User lookup

    func testThatItSendsAUserLookupRequest() async throws {
        // given
        let userId = UUID()
        let task = makeSearchTask(lookupUserId: userId)

        // when
        _ = await task.performUserLookup()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().first?.path, "/users/\(userId.transportString())")
    }

    func testThatItSendsAUserLookupRequest_IfApiVersionIsV2AndAbove() async throws {
        // given
        let userId = UUID()
        let domain = "wire.com"
        let task = makeSearchTask(lookupUserId: userId, domain: domain, apiVersion: .v2)

        // when
        _ = await task.performUserLookup()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/users/\(domain)/\(userId.transportString())"
        )
    }

    func testThatItCallsCompletionHandlerForUserLookup() async throws {
        // given
        var userId: UUID!
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockUser = remoteChanges.insertUser(withName: "User A")
            userId = UUID(uuidString: mockUser.identifier)!
        }
        let task = makeSearchTask(lookupUserId: userId)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performUserLookup()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.first?.name, "User A")
    }

    // MARK: Federated search

    func testThatItDoesNotSendAFederatedUserSearchRequest__WhenLocalSearchOnly() async throws {
        // given
        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: [.federated, .localResultsOnly])
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItSendsAFederatedUserSearchRequest() async throws {
        // given
        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        _ = await task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = try XCTUnwrap(mockTransportSession.receivedRequests().first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v3/search/contacts?q=john&domain=example.com&size=10")
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserExists() async throws {
        // given
        let federatedDomain = "example.com"

        mockTransportSession.federatedDomains = [federatedDomain]
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockUser = remoteChanges.insertUser(withName: "John Doe")
            mockUser.handle = "john"
            mockUser.domain = federatedDomain
        }

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearch()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.first?.name, "John Doe")
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserDoesntExist() async throws {
        // given
        mockTransportSession.federatedDomains = ["example.com"]

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearch()
        resultAggregator(&result)

        // then
        XCTAssertTrue(result.directory.isEmpty)
    }

    // MARK: Combined results

    func testThatRemoteResultsIncludePreviousLocalResults() async throws {
        // given
        let user = try await createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when - perform local search
        var result = SearchResult()
        let localResultAggregator = await task.performLocalSearch()
        localResultAggregator(&result)

        // then - local result contains user
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))

        // when - perform remote search
        let remoteResultAggregator = await task.performRemoteSearch()
        remoteResultAggregator(&result)

        // then - remote result still contains local user
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    func testThatLocalResultsIncludePreviousRemoteResults() async throws {
        // given
        _ = try await createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when - perform remote search
        var result = SearchResult()
        let remoteResultAggregator = await task.performRemoteSearch()
        remoteResultAggregator(&result)

        // then - remote result contains directory user
        XCTAssertEqual(result.directory.count, 1)

        // when - perform local search
        let localResultAggregator = await task.performLocalSearch()
        localResultAggregator(&result)

        // then - local result still contains directory user
        XCTAssertEqual(result.directory.count, 1)
    }

    func testThatTaskIsCompletedAfterLocalResult() async throws {
        // given
        let user = try await createConnectedUser(withName: "userA")
        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performLocalSearch()
        resultAggregator(&result)

        // then
        XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
    }

    func testThatTaskIsCompletedAfterRemoteResults() async throws {
        // given
        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        var result = SearchResult()
        let resultAggregator = await task.performRemoteSearch()
        resultAggregator(&result)

        // then
        XCTAssertEqual(result.directory.count, 1)
    }

    func testThatTaskIsCompletedOnlyAfterFinalResultArrives() async throws {
        // given
        _ = try await createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request)

        // when
        let result = await task.start()
        
        // then - verify both local and remote results are present
        XCTAssertEqual(result.contacts.count, 1)
        XCTAssertEqual(result.directory.count, 1)
    }

    // MARK: - Helpers

    private func makeSearchTask(
        request: SearchRequest,
        apiVersion: APIVersion = .v0
    ) -> SearchTask {
        SearchTask(
            type: .search(searchRequest: request),
            contextProvider: coreDataStack!,
            transportSession: mockTransportSession,
            searchUsersCache: mockCache,
            apiVersion: apiVersion
        )
    }

    private func makeSearchTask(
        lookupUserId: UUID,
        domain: String = "wire.com",
        apiVersion: APIVersion = .v0
    ) -> SearchTask {
        let qualifiedID = QualifiedID(uuid: lookupUserId, domain: domain)
        return SearchTask(
            type: .lookup(qualifiedID: qualifiedID),
            contextProvider: coreDataStack!,
            transportSession: mockTransportSession,
            searchUsersCache: mockCache,
            apiVersion: apiVersion
        )
    }

}
