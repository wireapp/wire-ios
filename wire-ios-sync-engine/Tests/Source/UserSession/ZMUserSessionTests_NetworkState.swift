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

import WireDataModelSupport
@testable import WireSyncEngine
import XCTest

final class ZMUserSessionTests_NetworkState: ZMUserSessionTestsBase {

    func testThatItSetsItselfAsADelegateOfTheTransportSessionAndForwardsUserClientID() {
        // given
        let userId = NSUUID.create()!

        mockPushChannel = MockPushChannel()
        cookieStorage = ZMPersistentCookieStorage(forServerName: "usersessiontest.example.com", userIdentifier: userId, useCache: true)
        let transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage, pushChannel: mockPushChannel)
        let mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        let coreDataStack = createCoreDataStack()
        let selfClient = coreDataStack.syncContext.performAndWait {
            self.setupSelfClient(inMoc: coreDataStack.syncContext)
        }

        // when
        let mockContextStore = MockLAContextStorable()
        mockContextStore.clear_MockMethod = { }
        let configuration = ZMUserSession.Configuration()

        var builder = ZMUserSessionBuilder()
        builder.withAllDependencies(
            appVersion: "00000",
            application: application,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            coreDataStack: coreDataStack,
            configuration: configuration,
            contextStorage: mockContextStore,
            earService: mockEARService,
            flowManager: flowManagerMock,
            mediaManager: mediaManager,
            mlsService: mockMLSService,
            proteusToMLSMigrationCoordinator: MockProteusToMLSMigrationCoordinating(),
            recurringActionService: mockRecurringActionService,
            sharedUserDefaults: sharedUserDefaults,
            transportSession: transportSession,
            userId: userId
        )
        let testSession = builder.build()
        testSession.setup(
            eventProcessor: nil,
            strategyDirectory: nil,
            syncStrategy: nil,
            operationLoop: nil,
            configuration: configuration,
            isDeveloperModeEnabled: false
        )
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // then
        XCTAssertTrue(self.transportSession.didCallSetNetworkStateDelegate)
        XCTAssertEqual(mockPushChannel.keepOpen, true)
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(mockPushChannel.clientID, selfClient.remoteIdentifier)
        }
        testSession.tearDown()
    }
}
