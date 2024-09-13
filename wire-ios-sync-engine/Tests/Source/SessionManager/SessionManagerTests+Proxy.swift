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

import Foundation
@testable import WireSyncEngine

final class SessionManagerProxyTests: IntegrationTest {
    var reachabilityWrapper: ReachabilityWrapper!
    var unauthenticatedSessionFactory: MockUnauthenticatedSessionFactory!
    var authenticatedSessionFactory: MockAuthenticatedSessionFactory!

    override func createSessionManager() {
        guard
            let application,
            let transportSession = mockTransportSession
        else {
            return XCTFail()
        }

        let reachability = MockReachability()

        reachabilityWrapper = ReachabilityWrapper(enabled: false, reachabilityClosure: { reachability })

        unauthenticatedSessionFactory = MockUnauthenticatedSessionFactory(
            transportSession: transportSession,
            environment: mockEnvironment,
            reachability: reachability
        )
        authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: mockMediaManager,
            flowManager: FlowManagerMock(),
            transportSession: transportSession,
            environment: mockEnvironment,
            reachability: reachability
        )

        let pushTokenService: PushTokenServiceInterface = mockPushTokenService ?? PushTokenService()
        application.pushTokenService = pushTokenService

        sessionManager = SessionManager(
            appVersion: "0.0.0",
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachabilityWrapper,
            delegate: self,
            application: application,
            pushRegistry: pushRegistry,
            dispatchGroup: dispatchGroup,
            environment: mockEnvironment,
            configuration: sessionManagerConfiguration,
            detector: jailbreakDetector,
            requiredPushTokenType: shouldProcessLegacyPushes ? .voip : .standard,
            pushTokenService: pushTokenService,
            callKitManager: MockCallKitManager(),
            proxyCredentials: nil,
            isUnauthenticatedTransportSessionReady: false,
            sharedUserDefaults: sharedUserDefaults,
            deleteUserLogs: {}
        )

        sessionManager?.loginDelegate = mockLoginDelegete

        sessionManager?.start(launchOptions: [:])

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_markNetworkSessionsAsReady_createsUnauthenticatedSession() {
        // GIVEN
        XCTAssertFalse(unauthenticatedSessionFactory.readyForRequests)

        // WHEN
        sessionManager?.markNetworkSessionsAsReady(true)

        // THEN
        XCTAssertTrue(reachabilityWrapper.enabled)
        XCTAssertTrue(unauthenticatedSessionFactory.readyForRequests)
        XCTAssertNotNil(sessionManager?.unauthenticatedSession)
        XCTAssertNotNil(sessionManager?.apiVersionResolver)
    }

    func test_markNetworkSessionsAsReady_sendsNotification() {
        // GIVEN
        XCTAssertFalse(unauthenticatedSessionFactory.readyForRequests)

        // EXPECT
        customExpectation(
            forNotification: NSNotification.Name(rawValue: ZMTransportSessionReachabilityIsEnabled),
            object: nil
        ) { _ -> Bool in
            true
        }

        // WHEN
        sessionManager?.markNetworkSessionsAsReady(true)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }
}
