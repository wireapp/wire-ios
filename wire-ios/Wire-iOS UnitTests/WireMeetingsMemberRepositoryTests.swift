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

import WireCallingDomain
import WireDataModel
import WireDataModelSupport
import WireNetwork
import WireNetworkSupport
import XCTest

@testable import Wire

final class WireMeetingsMemberRepositoryTests: XCTestCase {

    private var stackHelper: CoreDataStackHelper!
    private var stack: CoreDataStack!
    private var conversationsAPI: MockConversationsAPI!
    private var sut: WireMeetingsMemberRepository!
    private let modelHelper = ModelHelper()
    private let selfID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
    private let groupID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")

    override func setUp() async throws {
        stackHelper = CoreDataStackHelper()
        stack = try await stackHelper.createStack()
        conversationsAPI = MockConversationsAPI()
        let session = UserSessionMock()
        session.coreDataStack = stack
        sut = WireMeetingsMemberRepository(userSession: session, conversationsAPI: conversationsAPI)
        try await stack.syncContext.perform { [self] in
            modelHelper.createSelfUser(id: selfID.id, domain: selfID.domain, in: stack.syncContext)
            try stack.syncContext.save()
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        conversationsAPI = nil
        stack = nil
        try stackHelper.cleanupDirectory()
        stackHelper = nil
    }

    func testSearchGroupsIncludesActiveGroupsAndChannels() async throws {
        let context = stack.viewContext
        try await context.perform { [self] in
            makeGroup(name: "All hands group", in: context)
            makeGroup(name: "All hands channel", in: context).groupType = .channel
            let former = makeGroup(name: "All hands former", in: context)
            former.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: context))
            makeGroup(name: "All hands deleted", in: context).isDeletedRemotely = true
            makeGroup(name: "All hands meeting", in: context).groupType = .meeting
            makeGroup(name: "Other group", in: context)
            try context.save()
        }

        let results = try await sut.searchGroups(query: "  ALL HANDS  ")

        XCTAssertEqual(results.map(\.name), ["All hands channel", "All hands group"])
        XCTAssertEqual(results.map(\.isChannel), [true, false])
        let allGroups = try await sut.searchGroups(query: "")
        XCTAssertEqual(allGroups.map(\.name), ["All hands channel", "All hands group", "Other group"])
    }

    func testMembersUsesCurrentIDsIncludingGuestsAndSavesUnknownUsers() async throws {
        let guestID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let newID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let context = stack.syncContext
        try await context.perform { [self] in
            let (team, _, _) = modelHelper.createSelfTeam(numberOfUsers: 0, in: context)
            let guest = modelHelper.createUser(id: guestID.id, domain: guestID.domain, name: "Guest", in: context)
            let former = modelHelper.createUser(domain: "wire.com", name: "Former member", in: context)
            let conversation = modelHelper.createGroupConversation(
                id: groupID.id,
                with: [ZMUser.selfUser(in: context), guest, former],
                team: team,
                domain: groupID.domain,
                in: context
            )
            XCTAssertTrue(guest.isGuest(in: conversation))
            try context.save()
        }
        conversationsAPI.getConversationsFor_MockValue = .init(
            found: [.init(
                qualifiedID: groupID,
                type: .group,
                members: .init(
                    others: [guestID, newID, guestID].map { .init(qualifiedID: $0) },
                    selfMember: .init(qualifiedID: selfID)
                )
            )],
            notFound: [],
            failed: []
        )

        let members = try await sut.members(in: groupID)

        XCTAssertEqual(members.count, 3)
        XCTAssertEqual(Set(members.map(\.qualifiedID)), [selfID, guestID, newID])
        XCTAssertEqual(members.filter(\.isSelfUser).map(\.qualifiedID), [selfID])
        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations, [[groupID]])
        let readContext = stack.newBackgroundContext()
        let isStored = await readContext.perform {
            ZMUser.fetch(with: newID.id, domain: newID.domain, in: readContext) != nil
        }
        XCTAssertTrue(isStored)
    }

    func testMembersDoesNotUseCachedMembershipWhenSourceCannotBeRead() async throws {
        let context = stack.syncContext
        try await context.perform { [self] in
            makeGroup(name: "Cached group", id: groupID.id, in: context)
            try context.save()
        }
        conversationsAPI.getConversationsFor_MockValue = .init(
            found: [.init(
                qualifiedID: groupID,
                type: .group,
                members: .init(others: [], selfMember: nil)
            )],
            notFound: [],
            failed: []
        )

        do {
            _ = try await sut.members(in: groupID)
            XCTFail("Import must fail when the host is no longer a member")
        } catch WireMeetingsMemberRepository.Failure.sourceUnavailable {
            // Expected.
        }

        conversationsAPI.getConversationsFor_MockError = URLError(.notConnectedToInternet)
        do {
            _ = try await sut.members(in: groupID)
            XCTFail("Import must fail when current membership is unavailable")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }

    @discardableResult
    private func makeGroup(
        name: String,
        id: UUID = UUID(),
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = modelHelper.createGroupConversation(
            id: id,
            with: [ZMUser.selfUser(in: context)],
            domain: "wire.com",
            in: context
        )
        conversation.userDefinedName = name
        return conversation
    }
}
