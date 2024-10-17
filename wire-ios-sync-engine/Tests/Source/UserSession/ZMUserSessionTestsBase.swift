//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import WireSyncEngineSupport
import WireRequestStrategySupport
import Combine

final class ThirdPartyServices: NSObject, ThirdPartyServicesDelegate {

    var uploadCount = 0

    func userSessionIsReadyToUploadServicesData(userSession: WireSyncEngine.ZMUserSession) {
        uploadCount += 1
    }
}

class ZMUserSessionTestsBase: MessagingTest {

    var mockSessionManager: MockSessionManager!
    var mockPushChannel: MockPushChannel!
    var mockEARService: MockEARServiceInterface!
    var mockMLSService: MockMLSServiceInterface!
    var transportSession: RecordingMockTransportSession!
    var cookieStorage: ZMPersistentCookieStorage!
    var validCookie: Data!
    var baseURL: URL!
    var mediaManager: MediaManagerType!
    var flowManagerMock: FlowManagerMock!
    var dataChangeNotificationsCount: UInt = 0
    var thirdPartyServices: ThirdPartyServices!
    var mockSyncStateDelegate: MockSyncStateDelegate!
    var mockUseCaseFactory: MockUseCaseFactoryProtocol!
    var mockGetFeatureConfigsActionHandler: MockActionHandler<GetFeatureConfigsAction>!

    var sut: ZMUserSession!

    override func setUp() {
        super.setUp()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3Mock.self

        mockGetFeatureConfigsActionHandler = .init(result: .success(()), context: syncMOC.notificationContext)

        thirdPartyServices = ThirdPartyServices()
        dataChangeNotificationsCount = 0
        baseURL = URL(string: "http://bar.example.com")
        cookieStorage = ZMPersistentCookieStorage(
            forServerName: "usersessiontest.example.com",
            userIdentifier: .create(),
            useCache: true
        )
        mockPushChannel = MockPushChannel()
        transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage, pushChannel: mockPushChannel)
        mockSessionManager = MockSessionManager()
        mediaManager = MockMediaManager()
        flowManagerMock = FlowManagerMock()

        mockEARService = MockEARServiceInterface()
        mockEARService.setInitialEARFlagValue_MockMethod = { _ in }

        mockMLSService = MockMLSServiceInterface()
        mockMLSService.commitPendingProposalsIfNeeded_MockMethod = { }
        mockMLSService.onNewCRLsDistributionPoints_MockValue = PassthroughSubject<CRLsDistributionPoints, Never>()
            .eraseToAnyPublisher()
        mockMLSService.epochChanges_MockValue = .init { continuation in
            continuation.yield(MLSGroupID.random())
            continuation.finish()
        }

        mockUseCaseFactory = MockUseCaseFactoryProtocol()

        mockUseCaseFactory.createResolveOneOnOneUseCase_MockMethod = {
            let mockResolveOneOnOneConversationUseCase = MockResolveOneOnOneConversationsUseCaseProtocol()
            mockResolveOneOnOneConversationUseCase.invoke_MockMethod = { }
            return mockResolveOneOnOneConversationUseCase
        }

        sut = createSut()
        sut.thirdPartyServicesDelegate = self.thirdPartyServices
        sut.sessionManager = mockSessionManager

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        validCookie = "valid-cookue".data(using: .utf8)
    }

    override func tearDown() {
        clearCache()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3.self

        self.baseURL = nil
        self.cookieStorage = nil
        self.validCookie = nil
        self.thirdPartyServices = nil
        self.sut.thirdPartyServicesDelegate = nil
        self.mockSessionManager = nil
        self.mockMLSService = nil
        self.transportSession = nil
        self.mediaManager = nil
        self.flowManagerMock = nil
        self.mockUseCaseFactory = nil
        self.mockEARService.delegate = nil
        self.mockEARService = nil
        let sut = self.sut
        self.sut = nil
        mockGetFeatureConfigsActionHandler = nil
        sut?.tearDown()

        super.tearDown()
    }

    func createSut() -> ZMUserSession {
        createSut(earService: mockEARService)
    }

    func createSut(earService: EARServiceInterface) -> ZMUserSession {
        let mockStrategyDirectory = MockStrategyDirectory()
        let mockUpdateEventProcessor = MockUpdateEventProcessor()

        let mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = false

        let mockObserveMLSGroupVerificationStatusUseCase = MockObserveMLSGroupVerificationStatusUseCaseProtocol()
        mockObserveMLSGroupVerificationStatusUseCase.invoke_MockMethod = { }

        return ZMUserSession(
            userId: coreDataStack.account.userIdentifier,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManagerMock,
            analytics: nil,
            eventProcessor: mockUpdateEventProcessor,
            strategyDirectory: mockStrategyDirectory,
            syncStrategy: nil,
            operationLoop: nil,
            application: application,
            appVersion: "00000",
            coreDataStack: coreDataStack,
            configuration: .init(),
            earService: earService,
            mlsService: mockMLSService,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            sharedUserDefaults: sharedUserDefaults,
            useCaseFactory: mockUseCaseFactory,
            observeMLSGroupVerificationStatus: mockObserveMLSGroupVerificationStatusUseCase
        )
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
        let cachesURL = FileManager.default.cachesURLForAccount(with: userIdentifier, in: coreDataStack.applicationContainer)
        let items = try? FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)

        if let items {
            for item in items {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }
}
