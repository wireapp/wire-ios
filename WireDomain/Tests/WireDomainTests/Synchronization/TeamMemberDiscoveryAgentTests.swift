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

import WireNetwork
import WireNetworkSupport
import XCTest

@testable import WireDomain
@testable import WireDomainSupport

final class TeamMemberDiscoveryAgentTests: XCTestCase {

    private var sut: TeamMemberDiscoveryAgent!
    private var api: MockTeamsAPI!
    private var store: MockTeamLocalStoreProtocol!
    private var journal: Journal!

    override func setUp() async throws {
        api = MockTeamsAPI()
        store = MockTeamLocalStoreProtocol()
        journal = Journal(userID: UUID(), storage: UserDefaults.temporary())
        sut = TeamMemberDiscoveryAgent(api: api, store: store, journal: journal)
    }

    override func tearDown() async throws {
        api = nil
        store = nil
        journal = nil
        sut = nil
    }

    func test_discoverMembers_whenSelfUserIsNotInTeam_doesNothing() async {
        // Given
        store.selfTeamID_MockMethod = { nil }

        // When
        await sut.discoverMembers()

        // Then
        XCTAssertEqual(api.getNotificationsSinceNotificationIDMaxResults_Invocations.count, 0)
        XCTAssertEqual(store.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations.count, 0)
        XCTAssertNil(journal[.lastTeamNotificationID])
    }

    func test_discoverMembers_storesMembersAndAdvancesCursor() async throws {
        // Given
        store.selfTeamID_MockMethod = { Scaffolding.selfTeamID }
        store.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }
        api.getNotificationsSinceNotificationIDMaxResults_MockMethod = { _, _ in
            PayloadPager<[TeamNotification]> { _ in
                .init(
                    element: [Scaffolding.notification1, Scaffolding.notification2],
                    hasMore: false,
                    nextStart: Scaffolding.notification2.id.transportString()
                )
            }
        }

        // When
        await sut.discoverMembers()

        // Then
        let storeInvocations = store.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(storeInvocations[0].selfTeamID, Scaffolding.selfTeamID)
        XCTAssertEqual(storeInvocations[0].teamMembersInfo.count, 2)
        XCTAssertEqual(storeInvocations[0].teamMembersInfo[0].id, Scaffolding.member1UserID)
        XCTAssertEqual(storeInvocations[0].teamMembersInfo[1].id, Scaffolding.member2UserID)

        XCTAssertEqual(
            journal[.lastTeamNotificationID],
            Scaffolding.notification2.id.uuidString
        )
    }

    func test_discoverMembers_givenPersistedCursor_passesItToApi() async throws {
        // Given
        journal[.lastTeamNotificationID] = Scaffolding.priorCursor.uuidString
        store.selfTeamID_MockMethod = { Scaffolding.selfTeamID }
        store.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }
        api.getNotificationsSinceNotificationIDMaxResults_MockMethod = { _, _ in
            PayloadPager<[TeamNotification]> { _ in
                .init(
                    element: [Scaffolding.notification1],
                    hasMore: false,
                    nextStart: Scaffolding.notification1.id.transportString()
                )
            }
        }

        // When
        await sut.discoverMembers()

        // Then
        let invocations = api.getNotificationsSinceNotificationIDMaxResults_Invocations
        try XCTAssertCount(invocations, count: 1)
        XCTAssertEqual(invocations[0].sinceNotificationID, Scaffolding.priorCursor)
    }

    func test_discoverMembers_advancesCursorPerPage() async throws {
        // Given an api that returns two pages.
        store.selfTeamID_MockMethod = { Scaffolding.selfTeamID }
        store.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }
        api.getNotificationsSinceNotificationIDMaxResults_MockMethod = { _, _ in
            PayloadPager<[TeamNotification]> { nextSince in
                if nextSince == nil {
                    .init(
                        element: [Scaffolding.notification1],
                        hasMore: true,
                        nextStart: Scaffolding.notification1.id.transportString()
                    )
                } else {
                    .init(
                        element: [Scaffolding.notification2],
                        hasMore: false,
                        nextStart: Scaffolding.notification2.id.transportString()
                    )
                }
            }
        }

        // When
        await sut.discoverMembers()

        // Then: store called once per non-empty page, cursor reflects final page.
        let storeInvocations = store.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 2)
        XCTAssertEqual(
            journal[.lastTeamNotificationID],
            Scaffolding.notification2.id.uuidString
        )
    }

    func test_discoverMembers_givenMissedEvents_resetsCursorAndRetries() async throws {
        // Given a prior cursor and an api that signals missedEvents on the first
        // call, then succeeds on the retry.
        journal[.lastTeamNotificationID] = Scaffolding.priorCursor.uuidString
        store.selfTeamID_MockMethod = { Scaffolding.selfTeamID }
        store.storeTeamMembersSelfTeamIDTeamMembersInfo_MockMethod = { _, _ in }

        var callCount = 0
        api.getNotificationsSinceNotificationIDMaxResults_MockMethod = { _, _ in
            callCount += 1
            if callCount == 1 {
                return PayloadPager<[TeamNotification]> { _ in
                    throw TeamsAPIError.missedEvents
                }
            } else {
                return PayloadPager<[TeamNotification]> { _ in
                    .init(
                        element: [Scaffolding.notification1],
                        hasMore: false,
                        nextStart: Scaffolding.notification1.id.transportString()
                    )
                }
            }
        }

        // When
        await sut.discoverMembers()

        // Then: api called twice, second call with cursor reset to nil.
        let apiInvocations = api.getNotificationsSinceNotificationIDMaxResults_Invocations
        try XCTAssertCount(apiInvocations, count: 2)
        XCTAssertEqual(apiInvocations[0].sinceNotificationID, Scaffolding.priorCursor)
        XCTAssertNil(apiInvocations[1].sinceNotificationID)

        // Retry succeeded, so members were stored once and cursor advanced.
        let storeInvocations = store.storeTeamMembersSelfTeamIDTeamMembersInfo_Invocations
        try XCTAssertCount(storeInvocations, count: 1)
        XCTAssertEqual(
            journal[.lastTeamNotificationID],
            Scaffolding.notification1.id.uuidString
        )
    }

}

private enum Scaffolding {

    static let selfTeamID = UUID()
    static let priorCursor = UUID()
    static let member1UserID = UUID()
    static let member2UserID = UUID()

    static let notification1 = TeamNotification(
        id: UUID(),
        kind: .memberJoin(
            TeamMemberJoinNotification(
                teamID: selfTeamID,
                userID: member1UserID,
                time: Date(timeIntervalSince1970: 0)
            )
        )
    )

    static let notification2 = TeamNotification(
        id: UUID(),
        kind: .memberJoin(
            TeamMemberJoinNotification(
                teamID: selfTeamID,
                userID: member2UserID,
                time: Date(timeIntervalSince1970: 1)
            )
        )
    )

}
