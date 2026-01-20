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

import Combine
import WireDataModelSupport
import WireDomain
import WireLoggingSupport
import WireNetwork
import WireRequestStrategySupport
import WireTransportSupport

@testable import WireSyncEngine
@testable import WireSyncEngineSupport
@testable import WireTransport

class ZMUserSessionTestsBase: MessagingTest {

    var mockSessionManager: MockSessionManager!
    var mockEARService: MockEARServiceInterface!
    var mockMLSService: MockMLSServiceInterface!
    var backendEnvironment: WireTransport.BackendEnvironment!
    var wireAPIBackendEnvironment: WireNetwork.BackendEnvironment!
    var transportSession: RecordingMockTransportSession!
    var cookieStorage: ZMPersistentCookieStorage!
    var validCookie: Data!
    var baseURL: URL!
    var mediaManager: MediaManagerType!
    var flowManagerMock: FlowManagerMock!
    var dataChangeNotificationsCount: UInt = 0
    var mockFetchBackendMLSPublicKeysActionHandler: MockActionHandler<FetchBackendMLSPublicKeysAction>!

    var mockRecurringActionService: MockRecurringActionServiceInterface!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!

    var sut: ZMUserSession!

    override func setUp() {
        super.setUp()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3Mock.self

        let backendPublicKeys = BackendMLSPublicKeys(removal: .init(ed25519: .init([1, 2, 3])))
        mockFetchBackendMLSPublicKeysActionHandler = .init(
            result: .success(backendPublicKeys),
            context: syncMOC.notificationContext
        )

        dataChangeNotificationsCount = 0
        baseURL = URL(string: "http://bar.example.com")

        backendEnvironment = WireTransport.BackendEnvironment(
            title: "Mock backend environment",
            trustData: [],
            environmentType: .default,
            endpoints: BackendEndpoints(
                backendURL: baseURL,
                backendWSURL: baseURL,
                blackListURL: baseURL,
                teamsURL: baseURL,
                accountsURL: baseURL,
                websiteURL: baseURL,
                countlyURL: nil
            ),
            proxySettings: nil,
            certificateTrust: ServerCertificateTrust(trustData: [], currentDateProvider: .system)
        )

        wireAPIBackendEnvironment = WireNetwork.BackendEnvironment(
            url: backendEnvironment.backendURL,
            webSocketURL: backendEnvironment.backendWSURL,
            blacklistURL: backendEnvironment.blackListURL,
            pinnedKeys: [],
            proxySettings: nil
        )

        cookieStorage = ZMPersistentCookieStorage(
            forServerName: "usersessiontest.example.com",
            userIdentifier: .create(),
            useCache: true
        )

        transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage)
        mockSessionManager = MockSessionManager()
        mediaManager = MockMediaManager()
        flowManagerMock = FlowManagerMock()

        mockEARService = MockEARServiceInterface()
        mockEARService.setInitialEARFlagValue_MockMethod = { _ in }

        mockMLSService = MockMLSServiceInterface()
        mockMLSService.onNewCRLsDistributionPoints_MockValue = PassthroughSubject<CRLsDistributionPoints, Never>()
            .eraseToAnyPublisher()
        mockMLSService.epochChanges_MockValue = .init { continuation in
            continuation.yield(MLSGroupID.random())
            continuation.finish()
        }
        mockMLSService.setSyncDelegate_MockMethod = { _ in }
        mockMLSService.setResetBrokenMLSConversationDelegate_MockMethod = { _ in }

        mockRecurringActionService = MockRecurringActionServiceInterface()
        mockRecurringActionService.registerAction_MockMethod = { _ in }
        mockRecurringActionService.performActionsIfNeeded_MockMethod = {}
        mockMLSService.uploadKeyPackagesIfNeeded_MockMethod = {}
        sut = createSut()
        sut.sessionManager = mockSessionManager

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        validCookie = HTTPCookie.validCookieData()
    }

    override func tearDown() {
        clearCache()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3.self

        transportSession = nil
        backendEnvironment = nil
        wireAPIBackendEnvironment = nil
        baseURL = nil
        cookieStorage = nil
        validCookie = nil
        mockSessionManager = nil
        mockMLSService = nil
        transportSession = nil
        mediaManager = nil
        flowManagerMock = nil
        mockRecurringActionService = nil
        mockEARService.delegate = nil
        mockEARService = nil
        mockFetchBackendMLSPublicKeysActionHandler = nil
        mockCoreCryptoProvider = nil
        sut?.tearDown()
        super.tearDown()
    }

    func createSut() -> ZMUserSession {
        createSut(earService: mockEARService)
    }

    func createSut(earService: EARServiceInterface) -> ZMUserSession {
        let mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.registerEpochObserver_MockMethod = { _ in }
        let mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto

        let mockContextStorable = MockLAContextStorable()
        mockContextStorable.clear_MockMethod = {}

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
            coreDataStack: coreDataStack,
            coreCryptoProvider: mockCoreCryptoProvider,
            configuration: configuration,
            contextStorage: mockContextStorable,
            earService: earService,
            flowManager: flowManagerMock,
            mediaManager: mediaManager,
            mlsService: mockMLSService,
            proteusToMLSMigrationCoordinator: MockProteusToMLSMigrationCoordinating(),
            recurringActionService: mockRecurringActionService,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: URL(string: "file:///tmp/sharedContainerURL")!,
            transportSession: transportSession,
            userId: coreDataStack.account.userIdentifier,
            minTLSVersion: nil,
            journal: journal,
            logFilesProvider: logFilesProvider,
            faultyMLSRemovalKeysByDomain: [:]
        )

        let userSession = builder.build()
        userSession.setup(
            apiVersion: nil,
            eventProcessor: MockUpdateEventProcessor(),
            strategyDirectory: MockStrategyDirectory(),
            syncStrategy: nil,
            operationLoop: nil,
            configuration: configuration,
            isDeveloperModeEnabled: false
        )

        return userSession
    }

    func didChangeAuthenticationData() {
        dataChangeNotificationsCount += 1
    }

    func simulateLoggedInUser() {
        syncMOC.performAndWait {
            syncMOC.setPersistentStoreMetadata("clientID", key: ZMPersistedClientIdKey)
            ZMUser.selfUser(in: syncMOC).remoteIdentifier = UUID.create()
            cookieStorage.authenticationCookieData = validCookie
        }
    }

    private func clearCache() {
        let cachesURL = FileManager.default.cachesURLForAccount(
            with: userIdentifier,
            in: coreDataStack.applicationContainer
        )
        let items = try? FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)

        if let items {
            for item in items {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }
}
