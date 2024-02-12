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

struct SessionManagerBuilder {

    var maxNumberAccounts: Int = SessionManager.defaultMaxNumberAccounts
    var jailbreakDetector: JailbreakDetectorProtocol = MockJailbreakDetector()
    var dispatchGroup: ZMSDispatchGroup = ZMSDispatchGroup(label: "SessionManagerBuilder.internal")

    func build() -> SessionManager {
        let application = ApplicationMock()
        let environment = MockEnvironment()
        let reachability = MockReachability()
        let mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)

        let unauthenticatedSessionFactory = MockUnauthenticatedSessionFactory(
            transportSession: mockTransportSession,
            environment: environment,
            reachability: reachability
        )
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: mockTransportSession,
            environment: environment,
            reachability: reachability
        )
        let reachabilityWrapper = ReachabilityWrapper(
            enabled: true,
            reachabilityClosure: { reachability }
        )

        return SessionManager(
            maxNumberAccounts: maxNumberAccounts,
            appVersion: "0.0.0",
            authenticatedSessionFactory: authenticatedSessionFactory,
            unauthenticatedSessionFactory: unauthenticatedSessionFactory,
            reachability: reachabilityWrapper,
            delegate: nil,
            application: application,
            pushRegistry: PushRegistryMock(queue: nil),
            dispatchGroup: dispatchGroup,
            environment: environment,
            configuration: .defaultConfiguration,
            detector: jailbreakDetector,
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            proxyCredentials: nil,
            isUnauthenticatedTransportSessionReady: true,
            sharedUserDefaults: .temporary()
        )
    }
}
