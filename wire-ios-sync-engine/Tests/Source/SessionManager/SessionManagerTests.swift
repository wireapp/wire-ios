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

import LocalAuthentication
import PushKit
@testable import WireSyncEngine
import WireSyncEngineSupport
import WireTesting
import WireTransportSupport
import XCTest

final class SessionManagerTests: IntegrationTest {

    private var sessionManagerBuilder: SessionManagerBuilder!

    private var tmpDirectoryPath: URL { URL(fileURLWithPath: NSTemporaryDirectory()) }

    private var cachesDirectoryPath: URL {
        FileManager.default.randomCacheURL!
    }

    var mockDelegate: MockSessionManagerDelegate!

    override func setUp() {
        super.setUp()

        sessionManagerBuilder = SessionManagerBuilder()
        sessionManagerBuilder.dispatchGroup = dispatchGroup

        mockDelegate = MockSessionManagerDelegate()

        createSelfUserAndConversation()
    }

    override func tearDown() {
        mockDelegate = nil
        sessionManagerBuilder = nil

        super.tearDown()
    }

    // MARK: max account number
    func testThatDefaultMaxAccountNumberIs3_whenDefaultValueIsUsed() {
        // given and when
        let sut = sessionManagerBuilder.build()

        // then
        XCTAssertEqual(sut.maxNumberAccounts, 3)
    }

    func testThatMaxAccountNumberIs2_whenInitWithMaxAccountNumberAs2() {
        // given and when
        sessionManagerBuilder.maxNumberAccounts = 2
        let sut = sessionManagerBuilder.build()

        // then
        XCTAssertEqual(sut.maxNumberAccounts, 2)
    }

    func testThatItCreatesUnauthenticatedSessionAndNotifiesDelegateIfStoreIsNotAvailable() {
        // given
        mockDelegate.sessionManagerDidFailToLoginError_MockMethod = { _ in }

        let observer = MockSessionManagerObserver()
        let sut = sessionManagerBuilder.build()
        sut.delegate = mockDelegate

        // when
        sut.start(launchOptions: [:])

        // then
        XCTAssert(mockDelegate.sessionManagerDidChangeActiveUserSessionUserSession_Invocations.isEmpty)
        XCTAssertEqual(mockDelegate.sessionManagerDidFailToLoginError_Invocations.count, 1)
        XCTAssertNotNil(sut.unauthenticatedSession)
        XCTAssertEqual([], observer.createdUserSession)
    }

    func testThatItCreatesUserSessionAndNotifiesDelegateIfStoreIsAvailable() {
        // given
        mockDelegate.sessionManagerDidChangeActiveUserSessionUserSession_MockMethod = { _ in }

        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            return XCTFail()
        }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "", userIdentifier: currentUserIdentifier)
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = HTTPCookie.validCookieData()
        manager.addAndSelect(account)

        let sut = sessionManagerBuilder.build()
        sut.delegate = mockDelegate

        // when
        sut.start(launchOptions: [:])

        let observer = MockSessionManagerObserver()
        let token = sut.addSessionManagerCreatedSessionObserver(observer)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // then
        XCTAssertEqual(mockDelegate.sessionManagerDidChangeActiveUserSessionUserSession_Invocations.count, 1)
        XCTAssertNil(sut.unauthenticatedSession)
        withExtendedLifetime(token) {
            XCTAssertEqual(mockDelegate.sessionManagerDidChangeActiveUserSessionUserSession_Invocations, observer.createdUserSession)
        }
    }

    func testThatItNotifiesObserverWhenCreatingAndTearingDownSession() {

        // GIVEN
        let account = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = HTTPCookie.validCookieData()

        guard let application else { return XCTFail() }

        let sessionManagerExpectation = self.customExpectation(description: "Session manager and session is loaded")

        let observer = MockSessionManagerObserver()
        var createToken: Any?
        var destroyToken: Any?

        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            dispatchGroup: dispatchGroup,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            isUnauthenticatedTransportSessionReady: true,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: nil,
            deleteUserLogs: {},
            analyticsSessionConfiguration: nil
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        // WHEN
        createToken = testSessionManager.addSessionManagerCreatedSessionObserver(observer)
        destroyToken = testSessionManager.addSessionManagerDestroyedSessionObserver(observer)

        withExtendedLifetime(createToken) {
            testSessionManager.loadSession(for: account) { userSession in
                XCTAssertNotNil(userSession)
                sessionManagerExpectation.fulfill()
            }
        }

        // THEN
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual([testSessionManager.activeUserSession!], observer.createdUserSession)

        // AND WHEN
        withExtendedLifetime(destroyToken) {
            testSessionManager.tearDownBackgroundSession(for: account.userIdentifier)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual([account.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatItNotifiesDestroyedSessionObserverWhenCurrentSessionIsLoggedOut() {

        // GIVEN
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!
        let observer = MockSessionManagerObserver()
        let token = sessionManager?.addSessionManagerDestroyedSessionObserver(observer)

        // WHEN
        withExtendedLifetime(token) {
            sessionManager?.logoutCurrentSession()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        // THEN
        XCTAssertEqual([account.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatItNotifiesDestroyedSessionObserverWhenMemoryWarningReceived() {
        // GIVEN
        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true

        mockDelegate.sessionManagerDidFailToLoginError_MockMethod = { _ in }
        mockDelegate.sessionManagerDidChangeActiveUserSessionUserSession_MockMethod = { _ in }

        let account1 = self.createAccount()
        sessionManager!.environment.cookieStorage(for: account1).authenticationCookieData = HTTPCookie.validCookieData()

        let account2 = self.createAccount(with: UUID.create())
        sessionManager!.environment.cookieStorage(for: account2).authenticationCookieData = HTTPCookie.validCookieData()

        guard let application else { return XCTFail() }

        let sessionManagerExpectation = self.customExpectation(description: "Session manager and sessions are loaded")
        let observer = MockSessionManagerObserver()

        var destroyToken: Any?

        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: self.mockDelegate,
            application: application,
            dispatchGroup: dispatchGroup,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            detector: jailbreakDetector,
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            isUnauthenticatedTransportSessionReady: true,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: nil,
            deleteUserLogs: {},
            analyticsSessionConfiguration: nil
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: self.mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        // WHEN
        destroyToken = testSessionManager.addSessionManagerDestroyedSessionObserver(observer)

        testSessionManager.loadSession(for: account1) { userSession in
            XCTAssertNotNil(userSession)

            // load second account
            testSessionManager.loadSession(for: account2) { userSession in
                XCTAssertNotNil(userSession)
                sessionManagerExpectation.fulfill()
            }
        }

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(testSessionManager.backgroundUserSessions.count, 2)
        XCTAssertEqual(testSessionManager.backgroundUserSessions[account2.userIdentifier], testSessionManager.activeUserSession)

        withExtendedLifetime(destroyToken) {
            NotificationCenter.default.post(Notification(name: UIApplication.didReceiveMemoryWarningNotification))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual([account1.userIdentifier], observer.destroyedUserSessions)
    }

    func testThatJailbrokenDeviceCallsDelegateMethod() {
        // GIVEN
        mockDelegate.sessionManagerDidBlacklistJailbrokenDevice_MockMethod = { }

        guard let application else { return XCTFail() }
        let jailbreakDetector = MockJailbreakDetector(jailbroken: true)
        let configuration = SessionManagerConfiguration(blockOnJailbreakOrRoot: true)

        // WHEN
        _ = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: self.mockDelegate,
            application: application,
            environment: sessionManager!.environment,
            configuration: configuration,
            detector: jailbreakDetector,
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            isUnauthenticatedTransportSessionReady: true,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: nil,
            deleteUserLogs: {},
            analyticsSessionConfiguration: nil
        )

        XCTAssertEqual(mockDelegate.sessionManagerDidBlacklistJailbrokenDevice_Invocations.count, 1)
    }

    func testThatJailbrokenDeviceDeletesAccount() {
        // GIVEN
        mockDelegate.sessionManagerDidFailToLoginError_MockMethod = { _ in }
        mockDelegate.sessionManagerWillLogoutErrorUserSessionCanBeTornDown_MockMethod = { _, userSessionCanBeTornDown in
            userSessionCanBeTornDown?()
        }
        mockDelegate.sessionManagerDidBlacklistJailbrokenDevice_MockMethod = { }

        let jailbreakDetector = MockJailbreakDetector()
        jailbreakDetector.jailbroken = true
        sessionManagerBuilder.jailbreakDetector = jailbreakDetector

        let sut = sessionManagerBuilder.build()
        sut.configuration.wipeOnJailbreakOrRoot = true
        sut.delegate = mockDelegate

        // WHEN
        sut.start(launchOptions: [:])
        sut.accountManager.addAndSelect(createAccount())
        XCTAssertEqual(sut.accountManager.accounts.count, 1)

        // THEN
        performIgnoringZMLogError {
            sut.checkJailbreakIfNeeded()
        }
        XCTAssertEqual(sut.accountManager.accounts.count, 0)
    }

    func testAuthenticationAfterReboot() {
        // GIVEN
        let sut = sessionManagerBuilder.build()
        sut.delegate = mockDelegate

        let logoutExpectation = self.expectation(description: "Authentication after reboot")

        mockDelegate.sessionManagerDidFailToLoginError_MockMethod = { _ in }
        mockDelegate.sessionManagerWillLogoutErrorUserSessionCanBeTornDown_MockMethod = { error, userSessionCanBeTornDown in
            XCTAssertNil(sut.activeUserSession)
            XCTAssertEqual((error as? NSError)?.userSessionErrorCode, .needsAuthenticationAfterReboot)

            userSessionCanBeTornDown?()
            logoutExpectation.fulfill()
        }

        // WHEN && THEN
        sut.accountManager.addAndSelect(createAccount())
        sut.start(launchOptions: [:])
        XCTAssertEqual(sut.accountManager.accounts.count, 1)

        performIgnoringZMLogError {
            sut.performPostRebootLogout()
        }

        waitForExpectations(timeout: 1)
    }

    func testThatShouldPerformPostRebootLogoutReturnsFalseIfNotRebooted() {
        // GIVEN
        let sut = sessionManagerBuilder.build()
        sut.configuration.authenticateAfterReboot = true
        sut.accountManager.addAndSelect(createAccount())
        sut.start(launchOptions: [:])

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sut.accountManager.accounts.count, 1)
        SessionManager.previousSystemBootTime = ProcessInfo.processInfo.bootTime()

        // WHEN/THEN
        performIgnoringZMLogError {
            XCTAssertFalse(sut.shouldPerformPostRebootLogout())
        }
    }

    func testThatShouldPerformPostRebootLogoutReturnsFalseIfNoPreviousBootTimeExists() {

        // GIVEN
        let sut = sessionManagerBuilder.build()
        sut.configuration.authenticateAfterReboot = true
        sut.accountManager.addAndSelect(createAccount())

        // WHEN
        sut.start(launchOptions: [:])

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sut.accountManager.accounts.count, 1)
        ZMKeychain.deleteAllKeychainItems(withAccountName: SessionManager.previousSystemBootTimeContainer)

        // THEN
        performIgnoringZMLogError {
            XCTAssertFalse(sut.shouldPerformPostRebootLogout())
        }
    }

    func testThatItDestroyedCacheDirectoryAfterLoggedOut() throws {

        // GIVEN
        XCTAssertTrue(login())
        let sessionManager = try XCTUnwrap(sessionManager)
        let account = try XCTUnwrap(sessionManager.accountManager.selectedAccount)
        let observer = MockSessionManagerObserver()
        let token = sessionManager.addSessionManagerDestroyedSessionObserver(observer)

        let cachesDirectory = cachesDirectoryPath
        try FileManager.default.createDirectory(at: cachesDirectory, withIntermediateDirectories: true)
        let tempURL = cachesDirectory.appendingPathComponent("testFile.txt")
        let testData = "Test Message"
        try testData.write(to: tempURL, atomically: true, encoding: .utf8)
        XCTAssertFalse(tempURL.path.isEmpty)

        // WHEN
        withExtendedLifetime(token) {
            sessionManager.delete(account: account)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempURL.path))
    }

    func testThatItDestroyedTmpDirectoryAfterLoggedOut() throws {

        // GIVEN
        XCTAssertTrue(login())
        let account = try XCTUnwrap(sessionManager?.accountManager.selectedAccount)
        let observer = MockSessionManagerObserver()
        let token = sessionManager?.addSessionManagerDestroyedSessionObserver(observer)
        let tempUrl = tmpDirectoryPath.appendingPathComponent("testFile.txt")
        let testData = "Test Message"
        try testData.write(to: tempUrl, atomically: true, encoding: .utf8)
        let fCount = try FileManager.default.contentsOfDirectory(atPath: tmpDirectoryPath.path).count
        XCTAssertEqual(fCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempUrl.path))

        // WHEN
        withExtendedLifetime(token) {
            sessionManager?.delete(account: account)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let fileCount = try FileManager.default.contentsOfDirectory(atPath: tmpDirectoryPath.path).count

        // THEN
        XCTAssertEqual(fileCount, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempUrl.path))
    }

    func testThatItClearsCRLExpirationDatesAfterLogout() throws {
        // GIVEN
        XCTAssertTrue(login())
        let account = try XCTUnwrap(sessionManager?.accountManager.selectedAccount)

        let url = try XCTUnwrap( URL(string: "https://example.com"))
        let expirationDatesRepository = CRLExpirationDatesRepository(userID: account.userIdentifier)
        expirationDatesRepository.storeCRLExpirationDate(.now, for: url)

        // WHEN
        sessionManager?.delete(account: account)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertTrue(expirationDatesRepository.fetchAllCRLExpirationDates().isEmpty)
    }

    func testThatDeleteAccountWhenSingleUserClearsLastEventID() throws {
        // GIVEN
        XCTAssertTrue(login())
        let account = try XCTUnwrap(sessionManager?.accountManager.selectedAccount)

        let lastEventIDRepository = LastEventIDRepository(
            userID: account.userIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )
        lastEventIDRepository.storeLastEventID(UUID())

        // WHEN
        sessionManager?.delete(account: account)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
    }

    func testThatDeleteAccountWhenMultipleUsersClearsLastEventID() throws {
        // GIVEN
        XCTAssertTrue(login())

        let sut = try XCTUnwrap(sessionManager)
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())
        sut.accountManager.addAndSelect(account2)

        let lastEventIDRepository = LastEventIDRepository(
            userID: account2.userIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )
        lastEventIDRepository.storeLastEventID(UUID())

        // WHEN
        sessionManager?.delete(account: account2)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
    }

    // FIXME: [WPB-5638] this test will hang - [jacob]
    //
    // Since markAllConversationsAsRead() will schedule read up update message
    // which are never sent because the user sessions are not logged in. Refactor
    // SessionManager so that these tests can become unit tests where the user
    // sessions are mocked.
    func testThatItMarksConversationsAsRead() {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)
        sessionManager?.accountManager.addOrUpdate(account2)

        var conversations: [ZMConversation] = []

        let conversation1CreatedExpectation = self.customExpectation(description: "Conversation 1 created")

        self.sessionManager?.withSession(for: account1, perform: { createdSession in
            let syncContext = createdSession.syncContext
            syncContext.performAndWait {
                self.createSelfUserAndSelfConversation(in: syncContext)
                syncContext.saveOrRollback()
            }

            let conversation1 = createdSession.insertConversationWithUnreadMessage()
            conversations.append(conversation1)
            XCTAssertNotNil(conversation1.firstUnreadMessage)
            createdSession.managedObjectContext.saveOrRollback()
            conversation1CreatedExpectation.fulfill()
        })

        let conversation2CreatedExpectation = self.customExpectation(description: "Conversation 2 created")

        self.sessionManager?.withSession(for: account2, perform: { createdSession in
            let syncContext = createdSession.syncContext
            syncContext.performAndWait {
                self.createSelfUserAndSelfConversation(in: syncContext)
                syncContext.saveOrRollback()
            }

            let conversation2 = createdSession.insertConversationWithUnreadMessage()
            XCTAssertNotNil(conversation2.firstUnreadMessage)
            conversations.append(conversation2)
            createdSession.managedObjectContext.saveOrRollback()
            conversation2CreatedExpectation.fulfill()
        })

        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(conversations.count, 2)
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 2)

        // when
        let doneExpectation = self.customExpectation(description: "Conversations are marked as read")

        self.sessionManager?.markAllConversationsAsRead(completion: {
            doneExpectation.fulfill()
        })

        // then
        XCTAssertTrue(self.waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)

        // cleanup
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItLogsOutWithCompanyLoginURL() throws {
        // GIVEN
        let id = UUID(uuidString: "1E628B42-4C83-49B7-B2B4-EF27BFE503EF")!
        let url = URL(string: "wire://start-sso/wire-\(id)")!
        let presentationDelegate = MockPresentationDelegate()

        sessionManager?.presentationDelegate = presentationDelegate
        XCTAssertTrue(login())
        XCTAssertNotNil(userSession)

        // WHEN
        try sessionManager?.openURL(url)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(userSession)
    }

    // MARK: - Helpers

    private func createSelfUserAndSelfConversation(in context: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = UUID()

        let selfConversation = ZMConversation.insertNewObject(in: context)
        selfConversation.remoteIdentifier = ZMConversation.selfConversationIdentifier(in: context)
    }
}

extension IntegrationTest {

    func createAccount() -> Account {
        return createAccount(with: currentUserIdentifier)
    }

    func createAccount(with id: UUID) -> Account {
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail()
            fatalError()
        }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "Test Account", userIdentifier: id)
        manager.addOrUpdate(account)

        return account
    }
}

// MARK: - Mocks

class MockForegroundNotificationResponder: NSObject, ForegroundNotificationResponder {

    var notificationPermissionRequests: [UUID] = []

    func shouldPresentNotification(with userInfo: NotificationUserInfo) -> Bool {
        notificationPermissionRequests.append(userInfo.conversationID!)
        return true
    }
}
