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

class ThirdPartyServices: NSObject, ThirdPartyServicesDelegate {

    var uploadCount = 0

    func userSessionIsReadyToUploadServicesData(userSession: WireSyncEngine.ZMUserSession) {
        uploadCount += 1
    }
}

class ZMUserSessionTestsBase: MessagingTest {

    var mockSessionManager: MockSessionManager!
    var mockPushChannel: MockPushChannel!
    var mockMLSService: MockMLSServiceInterface!
    var transportSession: RecordingMockTransportSession!
    var cookieStorage: ZMPersistentCookieStorage!
    var validCookie: Data!
    var baseURL: URL!
    var sut: ZMUserSession!
    var mediaManager: MediaManagerType!
    var flowManagerMock: FlowManagerMock!
    var dataChangeNotificationsCount: UInt = 0
    var thirdPartyServices: ThirdPartyServices!
    var mockSyncStateDelegate: MockSyncStateDelegate!

    override func setUp() {
        super.setUp()

        WireCallCenterV3Factory.wireCallCenterClass = WireCallCenterV3Mock.self

        self.thirdPartyServices = ThirdPartyServices()
        self.dataChangeNotificationsCount = 0
        self.baseURL =  URL(string: "http://bar.example.com")
        self.cookieStorage = ZMPersistentCookieStorage(forServerName: "usersessiontest.example.com", userIdentifier: .create(), useCache: true)
        self.mockPushChannel = MockPushChannel()
        self.transportSession = RecordingMockTransportSession(cookieStorage: cookieStorage, pushChannel: mockPushChannel)
        self.mockSessionManager =  MockSessionManager()
        self.mediaManager = MockMediaManager()
        self.flowManagerMock = FlowManagerMock()

        createSut()

        self.sut.thirdPartyServicesDelegate = self.thirdPartyServices
        self.sut.sessionManager = mockSessionManager

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        self.validCookie = "valid-cookue".data(using: .utf8)
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
        let sut = self.sut
        self.sut = nil
        sut?.tearDown()

        super.tearDown()
    }

    func createSut() {
        let mockStrategyDirectory = MockStrategyDirectory()
        let mockUpdateEventProcessor = MockUpdateEventProcessor()
        let mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        mockMLSService = MockMLSServiceInterface()
        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = false
        sut = ZMUserSession(
            userId: coreDataStack.account.userIdentifier,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManagerMock,
            analytics: nil,
            updateEventProcessorFactory: { _, _, _, _, _ in mockUpdateEventProcessor },
            eventProcessor: mockUpdateEventProcessor,
            strategyDirectory: mockStrategyDirectory,
            syncStrategy: nil,
            operationLoop: nil,
            application: application,
            appVersion: "00000",
            coreDataStack: coreDataStack,
            configuration: .init(),
            mlsService: mockMLSService,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            sharedUserDefaults: sharedUserDefaults
        )
    }

    func didChangeAuthenticationData() {
        dataChangeNotificationsCount += 1
    }

    func simulateLoggedInUser() {
        syncMOC.setPersistentStoreMetadata("clientID", key: ZMPersistedClientIdKey)
        ZMUser.selfUser(in: syncMOC).remoteIdentifier = UUID.create()
        cookieStorage.authenticationCookieData = validCookie
    }

    private func clearCache() {
        let cachesURL = FileManager.default.cachesURLForAccount(with: userIdentifier, in: sut.sharedContainerURL)
        let items = try? FileManager.default.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)

        if let items {
            for item in items {
                try? FileManager.default.removeItem(at: item)
            }
        }
    }
}
