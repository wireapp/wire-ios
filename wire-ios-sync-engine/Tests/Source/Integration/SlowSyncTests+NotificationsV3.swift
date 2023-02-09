//
//  SlowSyncTests.swift
//  WireSyncEngine-iOS-Tests
//
//  Created by Jacob Persson on 04.09.19.
//  Copyright © 2019 Zeta Project Gmbh. All rights reserved.
//

import XCTest
import WireTesting
@testable import WireSyncEngine
import WireMockTransport

class SlowSyncTests_NotificationsV3: IntegrationTest {
    var previousAPIVersion: APIVersion?

    override func setUp() {
        // v3
        previousAPIVersion = BackendInfo.apiVersion
        BackendInfo.apiVersion = .v3

        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    override func tearDown() {
        super.tearDown()
        BackendInfo.apiVersion = previousAPIVersion
    }

    // MARK: - Slow sync with error

    func test_WhenSinceIdParam404DuringQuickSyncItTriggersASlowSync() {
        // GIVEN
        XCTAssertTrue(login())

        // add an invalid notifications/since
        let payload = ["id": "000", "time": Date().transportString()] as ZMTransportData
        let pushEvent = MockPushEvent(with: payload, uuid: self.mockTransportSession.invalidSinceParameter400)
        self.mockTransportSession.register(pushEvent)

        // WHEN
        self.performQuickSync()

        // THEN
        let result = wait(withTimeout: 1) {
            self.userSession?.applicationStatusDirectory?.syncStatus.isSlowSyncing == true
        }
        XCTAssertTrue(result, "it should perform slow sync")
    }
}
