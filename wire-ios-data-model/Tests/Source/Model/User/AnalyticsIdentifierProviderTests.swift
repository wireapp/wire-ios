//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - AnalyticsIdentifierProviderTests

final class AnalyticsIdentifierProviderTests: ModelObjectsTests {
    func testTheAnalyticsIdentifierIsGeneratedByProvider() {
        // Given
        let selfUser = createUser(selfUser: true, inTeam: true)

        let sut = AnalyticsIdentifierProvider(selfUser: selfUser)
        sut.setIdentifierIfNeeded()

        // Then
        XCTAssertNotNil(selfUser.analyticsIdentifier)
    }

    func testTheAnalyticsIdentifierIsNotAutomaticallyGenerated() {
        // Given, then
        XCTAssertNil(createUser(selfUser: true, inTeam: false).analyticsIdentifier)
        XCTAssertNil(createUser(selfUser: false, inTeam: false).analyticsIdentifier)
        XCTAssertNil(createUser(selfUser: false, inTeam: true).analyticsIdentifier)
    }

    func testTheAnalyticsIdentifierIsNotRegeneratedIfAValueExists() {
        // Given
        let selfUser = createUser(selfUser: true, inTeam: true)
        let sut = AnalyticsIdentifierProvider(selfUser: selfUser)
        sut.setIdentifierIfNeeded()

        let existingIdentifier = selfUser.analyticsIdentifier
        XCTAssertNotNil(existingIdentifier)

        // Then
        XCTAssertEqual(selfUser.analyticsIdentifier, existingIdentifier)
    }

    func testTheAnalyticsIdentifierIsEncodedAsUUIDTransportString() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = AnalyticsIdentifierProvider(selfUser: sut)
        provider.setIdentifierIfNeeded()

        // Then
        let id = try XCTUnwrap(sut.analyticsIdentifier)

        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testTheAnalyticsIdentifierIsBroadcastedInSelfConversationWhenGenerated() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = AnalyticsIdentifierProvider(selfUser: sut)

        let selfConversation = ZMConversation.selfConversation(in: uiMOC)
        XCTAssertTrue(selfConversation.allMessages.isEmpty)

        // When
        provider.setIdentifierIfNeeded()

        // Then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let identifier = try XCTUnwrap(sut.analyticsIdentifier)

        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(analyticsIdentifier: identifier), 1)
        }
    }

    func testTheAnalyticsIdentifierIsNotRebroadcastedInSelfConversation() throws {
        // Given
        let sut = createUser(selfUser: true, inTeam: true)

        let provider = AnalyticsIdentifierProvider(selfUser: sut)

        provider.setIdentifierIfNeeded()
        let identifier = try XCTUnwrap(sut.analyticsIdentifier)

        let selfConversation = ZMConversation.selfConversation(in: uiMOC)
        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(analyticsIdentifier: identifier), 1)
        }
        // When
        provider.setIdentifierIfNeeded()

        // Then
        try syncMOC.performAndWait {
            let selfConv = try syncMOC.existingObject(with: selfConversation.objectID) as! ZMConversation

            XCTAssertEqual(selfConv.numberOfDataTransferMessagesContaining(analyticsIdentifier: identifier), 1)
        }
    }
}

// MARK: - Helpers

extension AnalyticsIdentifierProviderTests {
    private func createUser(selfUser: Bool, inTeam: Bool) -> ZMUser {
        let user = selfUser ? self.selfUser! : createUser(in: uiMOC)
        guard inTeam else {
            return user
        }
        createMembership(in: uiMOC, user: user, team: createTeam(in: uiMOC))
        return user
    }
}

extension ZMConversation {
    fileprivate func numberOfDataTransferMessagesContaining(analyticsIdentifier: String) -> Int {
        allMessages.lazy
            .compactMap { $0 as? ZMClientMessage }
            .compactMap(\.underlyingMessage)
            .filter(\.hasDataTransfer)
            .map(\.dataTransfer.trackingIdentifier.identifier)
            .filter { $0 == analyticsIdentifier }
            .count
    }
}
