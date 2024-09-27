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

import Combine
import WireDataModelSupport
import WireRequestStrategySupport
import WireTransportSupport
@testable import WireSyncEngine
@testable import WireSyncEngineSupport
@testable import WireTransport

class ZMUserSessionTestsBase: MessagingTest {
    // MARK: Internal

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
    var mockSyncStateDelegate: MockSyncStateDelegate!
    var mockGetFeatureConfigsActionHandler: MockActionHandler<GetFeatureConfigsAction>!
    var mockRecurringActionService: MockRecurringActionServiceInterface!

    var sut: ZMUserSession!

    override func setUp() {
        super.setUp()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3Mock.self

        mockGetFeatureConfigsActionHandler = .init(result: .success(()), context: syncMOC.notificationContext)

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
        mockMLSService.commitPendingProposalsIfNeeded_MockMethod = {}
        mockMLSService.onNewCRLsDistributionPoints_MockValue = PassthroughSubject<CRLsDistributionPoints, Never>()
            .eraseToAnyPublisher()
        mockMLSService.epochChanges_MockValue = .init { continuation in
            continuation.yield(MLSGroupID.random())
            continuation.finish()
        }

        mockRecurringActionService = MockRecurringActionServiceInterface()
        mockRecurringActionService.registerAction_MockMethod = { _ in }
        mockRecurringActionService.performActionsIfNeeded_MockMethod = {}

        sut = createSut()
        sut.sessionManager = mockSessionManager

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        validCookie = HTTPCookie.validCookieData()
    }

    override func tearDown() {
        clearCache()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3.self

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
        let sut = sut
        self.sut = nil
        mockGetFeatureConfigsActionHandler = nil
        sut?.tearDown()

        super.tearDown()
    }

    func createSut() -> ZMUserSession {
        createSut(earService: mockEARService)
    }

    func createSut(earService: EARServiceInterface) -> ZMUserSession {
        let mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = false

        let mockContextStorable = MockLAContextStorable()
        mockContextStorable.clear_MockMethod = {}

        let configuration = ZMUserSession.Configuration()

        var builder = ZMUserSessionBuilder()
        builder.withAllDependencies(
            analytics: nil,
            appVersion: "00000",
            application: application,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            coreDataStack: coreDataStack,
            configuration: configuration,
            contextStorage: mockContextStorable,
            earService: earService,
            flowManager: flowManagerMock,
            mediaManager: mediaManager,
            mlsService: mockMLSService,
            proteusToMLSMigrationCoordinator: MockProteusToMLSMigrationCoordinating(),
            recurringActionService: mockRecurringActionService,
            sharedUserDefaults: sharedUserDefaults,
            transportSession: transportSession,
            userId: coreDataStack.account.userIdentifier
        )

        let userSession = builder.build()
        userSession.setup(
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

    // MARK: Private

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
