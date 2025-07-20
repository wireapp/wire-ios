//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireDataModel

final class TrackingIDProviderTests: ModelObjectsTests {

    func testTheTrackingIDIsGeneratedByProvider() {
        // Given
        let selfUser = createUser(selfUser: true, inTeam: true)

        let sut = TrackingIDProvider(selfUser: selfUser)
        sut.generateTrackingIDIfNeeded()

        // Then
        XCTAssertNotNil(selfUser.trackingID)
    }

    func testTheTrackingIDIsNotAutomaticallyGenerated() {
        // Given, then
        XCTAssertNil(createUser(selfUser: true, inTeam: false).trackingID)
        XCTAssertNil(createUser(selfUser: false, inTeam: false).trackingID)
        XCTAssertNil(createUser(selfUser: false, inTeam: true).trackingID)
    }

    func testTheTrackingIDIsNotRegeneratedIfAValueExists() {
        // Given
        let selfUser = createUser(selfUser: true, inTeam: true)
        let sut = TrackingIDProvider(selfUser: selfUser)
        sut.generateTrackingIDIfNeeded()

        let existingTrackingID = selfUser.trackingID
        XCTAssertNotNil(existingTrackingID)

        // Then
        XCTAssertEqual(selfUser.trackingID, existingTrackingID)
    }

    func testTheTrackingIDIsEncodedAsUUIDTransportString() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = TrackingIDProvider(selfUser: sut)
        provider.generateTrackingIDIfNeeded()

        // Then
        let id = try XCTUnwrap(sut.trackingID?.transportString())

        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testTheTrackingIDIsBroadcastedInSelfConversationWhenGenerated() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = TrackingIDProvider(selfUser: sut)

        let selfConversation = ZMConversation.selfConversation(in: uiMOC)
        XCTAssertTrue(selfConversation.allMessages.isEmpty)

        // When
        provider.generateTrackingIDIfNeeded()

        // Then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let trackingID = try XCTUnwrap(sut.trackingID)

        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(trackingID: trackingID), 1)
        }
    }

    func testTheTrackingIDIsNotRebroadcastedInSelfConversation() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = TrackingIDProvider(selfUser: sut)

        provider.generateTrackingIDIfNeeded()
        let trackingID = try XCTUnwrap(sut.trackingID)

        let selfConversation = ZMConversation.selfConversation(in: uiMOC)
        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(trackingID: trackingID), 1)
        }
        // When
        provider.generateTrackingIDIfNeeded()

        // Then
        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(trackingID: trackingID), 1)
        }
    }

}

// MARK: - Helpers

private extension TrackingIDProviderTests {

    func createUser(selfUser: Bool, inTeam: Bool) -> ZMUser {
        let user = selfUser ? self.selfUser! : createUser(in: uiMOC)
        guard inTeam else { return user }
        createMembership(in: uiMOC, user: user, team: createTeam(in: uiMOC))
        return user
    }

}

private extension ZMConversation {

    func numberOfDataTransferMessagesContaining(trackingID: UUID) -> Int {
        allMessages.lazy
            .compactMap { $0 as? ZMClientMessage }
            .compactMap(\.underlyingMessage)
            .filter(\.hasDataTransfer)
            .compactMap { UUID(transportString: $0.dataTransfer.trackingIdentifier.identifier) }
            .filter { $0 == trackingID }
            .count
    }

}
