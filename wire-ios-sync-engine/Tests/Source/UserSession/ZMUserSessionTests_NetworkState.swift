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

import WireDataModelSupport
import WireDomain
import WireLegacyLoggingSupport
import XCTest

@testable import WireLegacyLogging
@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ZMUserSessionTests_NetworkState: ZMUserSessionTestsBase {

    @MainActor
    func testThatItSetsItselfAsADelegateOfTheTransportSessionAndForwardsUserClientID() async throws {
        // given
        let userId = NSUUID.create()!

        mockPushChannel = MockPushChannel()
        cookieStorage = ZMPersistentCookieStorage(
            forServerName: "usersessiontest.example.com",
            userIdentifier: userId,
            useCache: true
        )
        let transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage, pushChannel: mockPushChannel)
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.registerEpochObserver_MockMethod = { _ in }
        let mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        let coreCryptoProvider = MockCoreCryptoProviderProtocol()
        coreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        coreCryptoProvider.registerMlsTransport_MockMethod = { _ in }
        coreCryptoProvider.registerEpochObserver_MockMethod = { _ in }
        let mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        let coreDataStack = try await createCoreDataStack()
        let selfClient = coreDataStack.syncContext.performAndWait {
            self.setupSelfClient(inMoc: coreDataStack.syncContext)
        }

        // when
        let mockContextStore = MockLAContextStorable()
        mockContextStore.clear_MockMethod = {}
        let configuration = ZMUserSession.Configuration()

        let journal = Journal(
            userID: coreDataStack.account.userIdentifier,
            storage: UserDefaults.temporary()
        )
        let logFilesProvider = LogFilesProvidingMock()

        var builder = ZMUserSessionBuilder()
        builder.withAllDependencies(
            backendEnvironment: backendEnvironment,
            wireAPIBackendEnvironment: wireAPIBackendEnvironment,
            currentAppVersion: "3.120.0",
            currentBuildNumber: "00000",
            application: application,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            coreDataStack: coreDataStack,
            coreCryptoProvider: coreCryptoProvider,
            configuration: configuration,
            contextStorage: mockContextStore,
            earService: mockEARService,
            flowManager: flowManagerMock,
            mediaManager: mediaManager,
            mlsService: mockMLSService,
            proteusToMLSMigrationCoordinator: MockProteusToMLSMigrationCoordinating(),
            recurringActionService: mockRecurringActionService,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: URL(string: "file:///tmp/sharedContainerURL")!,
            transportSession: transportSession,
            userId: userId,
            minTLSVersion: nil,
            journal: journal,
            logFilesProvider: logFilesProvider
        )
        let testSession = builder.build()
        testSession.setup(
            apiVersion: nil,
            eventProcessor: nil,
            strategyDirectory: nil,
            syncStrategy: nil,
            operationLoop: nil,
            configuration: configuration,
            isDeveloperModeEnabled: false
        )

        // then
        XCTAssertTrue(self.transportSession.didCallSetNetworkStateDelegate)
        XCTAssertEqual(mockPushChannel.keepOpen, true)
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(mockPushChannel.clientID, selfClient.remoteIdentifier)
        }
        testSession.tearDown()
    }
}
