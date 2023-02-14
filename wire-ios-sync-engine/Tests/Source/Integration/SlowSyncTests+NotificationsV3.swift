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

    override func _setUp() {
        setCurrentAPIVersion(.v3)
        super._setUp()
    }

    override func setUp() {
        setCurrentAPIVersion(.v3)
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    // MARK: - Slow sync with error

    func test_WhenSinceIdParam404DuringQuickSyncItTriggersASlowSync() {
        internalTestSlowSyncIsPerformedDuringQuickSync(withSinceParameterId: self.mockTransportSession.invalidSinceParameter400)
    }

    func test_WhenSinceIdParam400DuringQuickSyncItTriggersASlowSync() {
        internalTestSlowSyncIsPerformedDuringQuickSync(withSinceParameterId: self.mockTransportSession.unknownSinceParameter404)
    }

    func internalTestSlowSyncIsPerformedDuringQuickSync(withSinceParameterId sinceParameter: UUID) {
        // GIVEN
        XCTAssertTrue(login())

        // add an invalid /notifications/since
        self.mockTransportSession.overrideNextSinceParameter = sinceParameter

        // WHEN
        self.performQuickSync()

        // THEN
        let result = wait(withTimeout: 1) {
            self.userSession?.applicationStatusDirectory?.syncStatus.isSlowSyncing == true
        }
        XCTAssertTrue(result, "it should perform slow sync")
    }
}
