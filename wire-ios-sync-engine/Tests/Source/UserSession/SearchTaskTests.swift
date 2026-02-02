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

    func createConnectedUser(withName name: String, domain: String? = nil) -> ZMUser {
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = name
        user.remoteIdentifier = UUID.create()
        user.domain = domain

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user
        connection.status = .accepted

        uiMOC.saveOrRollback()

        return user
    }

    func createGroupConversation(withName name: String) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Me"
        conversation.userDefinedName = name
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        uiMOC.saveOrRollback()

        return conversation
    }

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
    /*
    // MARK: Contacts Search

    func testThatItFindsASingleUser() async throws {

        // given
        let resultArrived = customExpectation(description: "received result")
        let user = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "userA", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesFindUsersContainingButNotBeginningWithSearchString() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        _ = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "serA", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.count, 1)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsUsersBeginningWithSearchString() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user = createConnectedUser(withName: "userA")

        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItUsesAllQueryComponentsToFindAUser() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Some Body")
        _ = createConnectedUser(withName: "Some")
        _ = createConnectedUser(withName: "Any Body")

        let request = SearchRequest(query: "Some Body", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsSeveralUsers() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Grant")
        let user2 = createConnectedUser(withName: "Greg")
        _ = createConnectedUser(withName: "Bob")

        let request = SearchRequest(query: "Gr", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1, user2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchIsCaseInsensitive() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchIsInsensitiveToDiacritics() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user1])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatUserSearchOnlyReturnsConnectedUsers() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Somebody Blocked")
        user1.connection?.status = .blocked
        let user2 = createConnectedUser(withName: "Somebody Pending")
        user2.connection?.status = .pending
        let user3 = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "Some", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotReturnTheSelfUser() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.name = "Some self user"
        let user = createConnectedUser(withName: "Somebody")

        let request = SearchRequest(query: "Some", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.compactMap(\.user), [user])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesNotFindUsersWithOtherDomainsIfSearchDomainIsRequired() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user = createConnectedUser(withName: "userA", domain: "bella.com")

        let request = SearchRequest(query: "userA@bella.com", searchDomain: "anta.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.contacts.count, 0)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsUsersWithSameDomainAsSelfUser() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user = createConnectedUser(withName: "userA", domain: "anta.com")

        let request = SearchRequest(query: "userA@anta.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsUsersWithOtherDomainsIfSearchDomainIsNotRequired() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user = createConnectedUser(withName: "userA", domain: "bella.com")

        let request = SearchRequest(query: "userA@bella.com", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Team member local search

    func testThatItCanSearchForTeamMembersLocally() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        let member = Member.insertNewObject(in: uiMOC)

        user.name = "Member A"

        member.team = team
        member.user = user

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "@member", searchOptions: [.teamMembers], team: team)
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [user])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCanExcludeNonActiveTeamMembersLocally() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
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

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActiveTeamMembersLocally_WhenSelfUserWasCreatedByThem() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
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

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCanExcludeNonActivePartnersLocally() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
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

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA, userB])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSearchingWithExactHandle() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

        userA.name = "Member A"
        userA.handle = "abc"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .partner

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "@abc", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItIncludesNonActivePartnersLocally_WhenSelfUserCreatedPartner() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let userA = ZMUser.insertNewObject(in: uiMOC)
        let memberA = Member.insertNewObject(in: uiMOC) // non-active partner

        userA.name = "Member A"
        userA.handle = "abc"

        memberA.team = team
        memberA.user = userA
        memberA.permissions = .partner
        memberA.createdBy = ZMUser.selfUser(in: uiMOC)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "", searchOptions: [.teamMembers, .excludeNonActivePartners], team: team)
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.compactMap(\.user), [userA])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Conversation Search

    func testThatItFindsASingleConversation() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "Somebody", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItDoesFindConversationsUsingPartialNames() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = createGroupConversation(withName: "Somebody")

        let request = SearchRequest(query: "mebo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsSeveralConversations() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation1 = createGroupConversation(withName: "Candy Apple Records")
        let conversation2 = createGroupConversation(withName: "Landspeed Records")
        _ = createGroupConversation(withName: "New Day Rising")

        let request = SearchRequest(query: "Records", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatConversationSearchIsCaseInsensitive() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = createGroupConversation(withName: "SoMEBody")

        let request = SearchRequest(query: "someBodY", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatConversationSearchIsInsensitiveToDiacritics() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = createGroupConversation(withName: "Sömëbodÿ")

        let request = SearchRequest(query: "Sømebôdy", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOnlyFindsGroupConversations() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let groupConversation = createGroupConversation(withName: "Group Conversation")
        let oneOnOneConversation = createGroupConversation(withName: "OneOnOne Conversation")
        oneOnOneConversation.conversationType = .oneOnOne
        let selfConversation = createGroupConversation(withName: "Self Conversation")
        selfConversation.conversationType = .self

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Conversation", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [groupConversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsConversationsThatDoNotHaveAUserDefinedName() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let user1 = createConnectedUser(withName: "Shinji")
        let user2 = createConnectedUser(withName: "Asuka")
        let user3 = createConnectedUser(withName: "Rëï")

        conversation.addParticipantsAndUpdateConversationState(users: [user1, user2, user3], role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations, .contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
            XCTAssertEqual(result.contacts.compactMap(\.user), [user3])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFindsConversationsThatContainsSearchTermOnlyInParticipantName() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation = createGroupConversation(withName: "Summertime")
        let user = createConnectedUser(withName: "Rëï")
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Rei", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOrdersConversationsByUserDefinedName() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let conversation1 = createGroupConversation(withName: "FooA")
        let conversation2 = createGroupConversation(withName: "FooC")
        let conversation3 = createGroupConversation(withName: "FooB")

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation2])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItOrdersConversationsByUserDefinedNameFirstAndByParticipantNameSecond() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let user1 = createConnectedUser(withName: "Bla")
        let user2 = createConnectedUser(withName: "FooB")

        let conversation1 = createGroupConversation(withName: "FooA")
        let conversation2 = createGroupConversation(withName: "Bar")
        let conversation3 = createGroupConversation(withName: "FooB")
        let conversation4 = createGroupConversation(withName: "Bar")

        conversation2.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation4.addParticipantsAndUpdateConversationState(users: [user1, user2], role: nil)

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Foo", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [conversation1, conversation3, conversation4])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItFiltersConversationWhenTheQueryStartsWithAtSymbol() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        _ = createGroupConversation(withName: "New Day Rising")
        _ = createGroupConversation(withName: "Landspeed Records")

        let request = SearchRequest(query: "@records", searchOptions: [.conversations])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.conversations, [])
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItReturnsAllConversationsWhenPassingTeamParameter() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let team = Team.insertNewObject(in: uiMOC)
        let conversationInTeam = createGroupConversation(withName: "Beach Club")
        let conversationNotInTeam = createGroupConversation(withName: "Beach Club")

        conversationInTeam.team = team

        uiMOC.saveOrRollback()

        let request = SearchRequest(query: "Beach", searchOptions: [.conversations], team: team)
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(Set(result.conversations), Set([conversationInTeam, conversationNotInTeam]))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Directory Search

    func testThatItSendsASearchRequest() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        task.performRemoteSearch()
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
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 0)
    }

    func testThatItDoesNotSendASearchRequestIfLocalResultsOnly() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.directory, .localResultsOnly])
        let task = makeSearchTask(request: request)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockTransportSession.receivedRequests().count, 0)
    }

    func testThatItEncodesAPlusCharacterInTheSearchURL() async throws {
        // given
        let request = SearchRequest(query: "foo+bar@example.com", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // when
        task.performRemoteSearch()
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
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/search/contacts?q=$%26%2B,/:;%3D?&size=10"
        )
    }

    func testThatItCallsCompletionHandlerForDirectorySearch() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let request = SearchRequest(query: "User", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "User A")
        }

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "User A")
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
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
        task.performRemoteSearch()
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
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItCallsCompletionHandlerForTeamMemberDirectorySearch() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
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

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.teamMembers.first?.name, "User A")
            XCTAssertEqual(result.teamMembers.first?.teamRole, .admin)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Services search

    func testThatItSendsASearchServicesRequest() async throws {
        // given
        let request = SearchRequest(query: "Steve O'Hara & Söhne", searchOptions: [.services])
        let task = makeSearchTask(request: request)

        // when
        task.performRemoteSearchForServices()
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
        task.performRemoteSearchForServices()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItCallsCompletionHandlerForServicesSearch() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        let request = SearchRequest(query: "Service", searchOptions: [.services])
        let task = makeSearchTask(request: request)

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertService(
                withName: "Service A",
                identifier: UUID().transportString(),
                provider: UUID().transportString()
            )
        }

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.services.first?.name, "Service A")
        }

        // when
        task.performRemoteSearchForServices()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
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
        task.performUserLookup()
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
        task.performUserLookup()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(
            mockTransportSession.receivedRequests().first?.path,
            "/v2/users/\(domain)/\(userId.transportString())"
        )
    }

    func testThatItCallsCompletionHandlerForUserLookup() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")

        var userId: UUID!
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockUser = remoteChanges.insertUser(withName: "User A")
            userId = UUID(uuidString: mockUser.identifier)!
        }
        let task = makeSearchTask(lookupUserId: userId)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "User A")
        }

        // when
        task.performUserLookup()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Federated search

    func testThatItDoesNotSendAFederatedUserSearchRequest__WhenLocalSearchOnly() async throws {
        // given
        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: [.federated, .localResultsOnly])
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(mockTransportSession.receivedRequests().isEmpty)
    }

    func testThatItSendsAFederatedUserSearchRequest() async throws {
        // given
        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let request = try XCTUnwrap(mockTransportSession.receivedRequests().first)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.path, "/v3/search/contacts?q=john&domain=example.com&size=10")
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserExists() async throws {
        // given
        let federatedDomain = "example.com"
        let resultArrived = customExpectation(description: "received result")

        mockTransportSession.federatedDomains = [federatedDomain]
        mockTransportSession.performRemoteChanges { remoteChanges in
            let mockUser = remoteChanges.insertUser(withName: "John Doe")
            mockUser.handle = "john"
            mockUser.domain = federatedDomain
        }

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertEqual(result.directory.first?.name, "John Doe")
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItCallsCompletionHandlerForFederatedUserSearch_WhenUserDoesntExist() async throws {
        // given
        let resultArrived = customExpectation(description: "received result")
        mockTransportSession.federatedDomains = ["example.com"]

        let searchRequest = SearchRequest(query: "john@example.com", searchOptions: .federated)
        let task = makeSearchTask(request: searchRequest, apiVersion: .v3)

        // expect
        task.addResultHandler { result, _ in
            resultArrived.fulfill()
            XCTAssertTrue(result.directory.isEmpty)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    // MARK: Combined results

    func testThatRemoteResultsIncludePreviousLocalResults() async throws {
        // given
        let localResultArrived = customExpectation(description: "received local result")
        let user = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // expect
        task.addResultHandler { result, _ in
            localResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // given
        let remoteResultArrived = customExpectation(description: "received remote result")

        // expect
        task.addResultHandler { result, _ in
            remoteResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatLocalResultsIncludePreviousRemoteResults() async throws {
        // given
        let remoteResultArrived = customExpectation(description: "received remote result")
        _ = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // expect
        task.addResultHandler { result, _ in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // given
        let localResultArrived = customExpectation(description: "received local result")

        // expect
        task.addResultHandler { result, _ in
            localResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedAfterLocalResult() async throws {
        // given
        let localResultArrived = customExpectation(description: "received local result")
        let user = createConnectedUser(withName: "userA")
        let request = SearchRequest(query: "user", searchOptions: [.contacts])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { result, completed in
            localResultArrived.fulfill()
            XCTAssertTrue(result.contacts.compactMap(\.user).contains(user))
            XCTAssertTrue(completed)
        }

        // when
        task.performLocalSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedAfterRemoteResults() async throws {
        // given
        let remoteResultArrived = customExpectation(description: "received remote result")
        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.directory])
        let task = makeSearchTask(request: request, apiVersion: .v2)

        // expect
        task.addResultHandler { result, completed in
            remoteResultArrived.fulfill()
            XCTAssertEqual(result.directory.count, 1)
            XCTAssertTrue(completed)
        }

        // when
        task.performRemoteSearch()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatTaskIsCompletedOnlyAfterFinalResultArrives() async throws {
        // given
        let intermediateResultArrived = customExpectation(description: "received intermediate result")
        let finalResultsArrived = customExpectation(description: "received final result")
        _ = createConnectedUser(withName: "userA")

        mockTransportSession.performRemoteChanges { remoteChanges in
            remoteChanges.insertUser(withName: "UserB")
        }

        let request = SearchRequest(query: "user", searchOptions: [.contacts, .directory])
        let task = makeSearchTask(request: request)

        // expect
        task.addResultHandler { _, completed in
            if completed {
                finalResultsArrived.fulfill()
            } else {
                intermediateResultArrived.fulfill()
            }
        }

        // when
        task.start()
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
     */

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
