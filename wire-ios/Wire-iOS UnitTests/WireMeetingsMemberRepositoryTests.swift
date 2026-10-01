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
    private var usersAPI: MockUsersAPI!
    private var sut: WireMeetingsMemberRepository!
    private let modelHelper = ModelHelper()
    private let selfID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
    private let groupID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
    private let teamID = UUID()

    override func setUp() async throws {
        stackHelper = CoreDataStackHelper()
        stack = try await stackHelper.createStack()
        conversationsAPI = MockConversationsAPI()
        usersAPI = MockUsersAPI()
        let session = UserSessionMock()
        session.coreDataStack = stack
        sut = WireMeetingsMemberRepository(
            userSession: session,
            conversationsAPI: conversationsAPI,
            usersAPI: usersAPI
        )
        try await stack.syncContext.perform { [self] in
            modelHelper.createSelfUser(id: selfID.id, domain: selfID.domain, in: stack.syncContext)
            try stack.syncContext.save()
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        conversationsAPI = nil
        usersAPI = nil
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

    func testMembersUsesCurrentTeamProfilesAndSavesUnknownUsers() async throws {
        let guestID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let newID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let context = stack.syncContext
        try await context.perform { [self] in
            let (team, _, _) = modelHelper.createSelfTeam(numberOfUsers: 0, in: context)
            let guest = modelHelper.createUser(id: guestID.id, domain: guestID.domain, name: "Guest", in: context)
            guest.handle = "old-handle"
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
        usersAPI.getUsersUserIDs_MockValue = .init(
            found: [
                makeProfile(id: selfID, teamID: teamID),
                makeProfile(id: guestID, teamID: teamID, name: "Updated member", handle: "updated-member"),
                makeProfile(id: newID, teamID: teamID, name: "New member", handle: "new-member")
            ],
            failed: []
        )

        let members = try await sut.members(in: groupID)

        XCTAssertEqual(members.count, 3)
        XCTAssertEqual(Set(members.map(\.qualifiedID)), [selfID, guestID, newID])
        XCTAssertEqual(members.filter(\.isSelfUser).map(\.qualifiedID), [selfID])
        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations, [[groupID]])
        XCTAssertEqual(members.first { $0.qualifiedID == guestID }?.name, "Updated member")
        XCTAssertEqual(members.first { $0.qualifiedID == guestID }?.handle, "updated-member")
        XCTAssertEqual(members.first { $0.qualifiedID == newID }?.name, "New member")
        XCTAssertEqual(members.first { $0.qualifiedID == newID }?.handle, "new-member")
        let readContext = stack.newBackgroundContext()
        let storedProfile = await readContext.perform {
            let user = ZMUser.fetch(with: newID.id, domain: newID.domain, in: readContext)
            return (user?.name, user?.handle)
        }
        XCTAssertEqual(storedProfile.0, "New member")
        XCTAssertEqual(storedProfile.1, "new-member")
    }

    func testMembersFiltersGuestsAndRequiresCompleteProfiles() async throws {
        let memberID = WireCallingDomain.QualifiedID(id: UUID(), domain: "wire.com")
        let federatedID = WireCallingDomain.QualifiedID(id: memberID.id, domain: "other.wire.com")
        let host = makeProfile(id: selfID, teamID: teamID)
        let teammate = makeProfile(id: .init(id: UUID(), domain: selfID.domain), teamID: teamID)
        let guests = [
            makeProfile(id: memberID, teamID: nil),
            makeProfile(id: memberID, teamID: UUID()),
            makeProfile(id: federatedID, teamID: teamID)
        ]
        for guest in guests {
            conversationsAPI.getConversationsFor_MockValue = .init(
                found: [.init(
                    qualifiedID: groupID,
                    type: .group,
                    members: .init(
                        others: [
                            .init(qualifiedID: guest.id, conversationRole: "wire_admin"),
                            .init(qualifiedID: teammate.id)
                        ],
                        selfMember: .init(qualifiedID: selfID)
                    ),
                    groupType: .channel
                )],
                notFound: [],
                failed: []
            )
            usersAPI.getUsersUserIDs_MockValue = .init(found: [host, guest, teammate], failed: [])
            let members = try await sut.members(in: groupID)
            XCTAssertEqual(Set(members.map(\.qualifiedID)), [selfID, teammate.id])
        }

        for failedIDs in [[], [federatedID]] {
            usersAPI.getUsersUserIDs_MockValue = .init(found: [host], failed: failedIDs)
            do {
                _ = try await sut.members(in: groupID)
                XCTFail("Import must fail when a current member's profile cannot be checked")
            } catch WireMeetingsMemberRepository.Failure.invalidMember {
                // Expected; missing profiles must not become a partial import.
            }
        }
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

    private func makeProfile(
        id: WireCallingDomain.QualifiedID,
        teamID: UUID?,
        name: String = "Member",
        handle: String? = nil
    ) -> WireNetwork.User {
        .init(
            id: id, name: name, handle: handle, teamID: teamID, type: .regular, accentID: 0,
            assets: [], deleted: false, email: nil, expiresAt: nil, app: nil, service: nil,
            supportedProtocols: [.mls], legalholdStatus: .disabled
        )
    }
}
