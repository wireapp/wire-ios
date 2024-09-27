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
import WireTesting
@testable import WireSyncEngine

final class SessionManagerMultiUserSessionTests: IntegrationTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()

        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true
    }

    func testThatItLoadsAndKeepsBackgroundUserSession() {
        // GIVEN
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account1 = Account(userName: "Test Account 1", userIdentifier: currentUserIdentifier)
        manager.addOrUpdate(account1)

        let account2 = Account(userName: "Test Account 2", userIdentifier: UUID())
        manager.addOrUpdate(account2)
        // WHEN
        weak var sessionForAccount1Reference: ZMUserSession?
        let session1LoadedExpectation = customExpectation(description: "Session for account 1 loaded")
        sessionManager!.withSession(for: account1, perform: { sessionForAccount1 in
            // THEN
            session1LoadedExpectation.fulfill()
            XCTAssertNotNil(sessionForAccount1.managedObjectContext)
            sessionForAccount1Reference = sessionForAccount1
        })
        // WHEN
        weak var sessionForAccount2Reference: ZMUserSession?
        let session2LoadedExpectation = customExpectation(description: "Session for account 2 loaded")
        sessionManager!.withSession(for: account1, perform: { sessionForAccount2 in
            // THEN
            session2LoadedExpectation.fulfill()
            XCTAssertNotNil(sessionForAccount2.managedObjectContext)
            sessionForAccount2Reference = sessionForAccount2
        })

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(sessionForAccount1Reference)
            XCTAssertNotNil(sessionForAccount2Reference)

            self.sessionManager!.tearDownAllBackgroundSessions()
        })
    }

    func testThatItUnloadsUserSession() {
        // GIVEN
        let account = createAccount()

        // WHEN
        let sessionLoadedExpectation = customExpectation(description: "Session loaded")
        sessionManager!.withSession(for: account, perform: { session in
            XCTAssertNotNil(session.managedObjectContext)
            sessionLoadedExpectation.fulfill()
        })

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // THEN
        XCTAssertNotNil(sessionManager!.backgroundUserSessions[account.userIdentifier])

        // AND WHEN
        sessionManager!.tearDownAllBackgroundSessions()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertNil(sessionManager!.backgroundUserSessions[account.userIdentifier])
    }

    func testThatItDoesNotUnloadActiveUserSessionFromMemoryWarning() throws {
        // GIVEN
        let account = createAccount()
        let sessionManager = try XCTUnwrap(sessionManager)
        sessionManager.environment.cookieStorage(for: account).authenticationCookieData = HTTPCookie.validCookieData()

        let application = try XCTUnwrap(application)

        let sessionManagerExpectation = expectation(description: "Session manager and session is loaded")

        // WHEN
        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            environment: sessionManager.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            isUnauthenticatedTransportSessionReady: true,
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: nil,
            deleteUserLogs: {}
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        testSessionManager.loadSession(for: account) { userSession in
            XCTAssertNotNil(userSession)
            sessionManagerExpectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 0.5)

        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // WHEN
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        // THEN
        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // CLEANUP
        testSessionManager.tearDownAllBackgroundSessions()
    }

    func testThatItUnloadBackgroundUserSessionFromMemoryWarning() {
        // GIVEN
        let account = createAccount()
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = HTTPCookie.validCookieData()

        guard let application else {
            return XCTFail()
        }

        let sessionManagerExpectation = customExpectation(description: "Session manager and session is loaded")

        // WHEN
        let testSessionManager = SessionManager(
            appVersion: "0.0.0",
            mediaManager: mockMediaManager,
            analytics: nil,
            delegate: nil,
            application: application,
            environment: sessionManager!.environment,
            configuration: SessionManagerConfiguration(blacklistDownloadInterval: -1),
            requiredPushTokenType: .standard,
            callKitManager: MockCallKitManager(),
            sharedUserDefaults: sharedUserDefaults,
            minTLSVersion: nil,
            deleteUserLogs: {}
        )

        let environment = MockEnvironment()
        let reachability = MockReachability()
        let authenticatedSessionFactory = MockAuthenticatedSessionFactory(
            application: application,
            mediaManager: MockMediaManager(),
            flowManager: FlowManagerMock(),
            transportSession: mockTransportSession,
            environment: environment,
            reachability: reachability
        )

        testSessionManager.authenticatedSessionFactory = authenticatedSessionFactory
        testSessionManager.start(launchOptions: [:])

        testSessionManager.withSession(for: account) { userSession in
            XCTAssertNotNil(userSession)
            sessionManagerExpectation.fulfill()
        }

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        XCTAssertNotNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // WHEN
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        // THEN
        XCTAssertNil(testSessionManager.backgroundUserSessions[account.userIdentifier])

        // CLEANUP
        testSessionManager.tearDownAllBackgroundSessions()
    }

    func prepareSession(for account: Account) {
        weak var weakSession: ZMUserSession?

        autoreleasepool {
            var session: ZMUserSession! = nil
            self.sessionManager?.withSession(for: account, perform: { createdSession in
                session = createdSession
                weakSession = createdSession
            })

            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

            let selfUser = ZMUser.selfUser(inUserSession: session)
            selfUser.remoteIdentifier = currentUserIdentifier

            self.sessionManager!.tearDownAllBackgroundSessions()
            XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            session = nil
            XCTAssertNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])
        }
        userSession = nil
        XCTAssertNil(weakSession)
    }

    func testThatItLoadsAccountForPush() {
        // GIVEN
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        sessionManager?.accountManager.addOrUpdate(account)

        prepareSession(for: account)

        let payload: [AnyHashable: Any] = [
            "data": [
                "user": currentUserIdentifier.transportString(),
            ],
        ]

        // WHEN
        let pushCompleted = customExpectation(description: "Push completed")
        sessionManager?.processIncomingRealVoIPPush(payload: payload, completion: {
            DispatchQueue.main.async {
                // THEN
                XCTAssertNotNil(self.sessionManager!.backgroundUserSessions[account.userIdentifier])

                // CLEANUP
                self.sessionManager!.tearDownAllBackgroundSessions()
                pushCompleted.fulfill()
            }
        })

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func testThatItLoadsOnlyOneAccountForPush() {
        // GIVEN
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        sessionManager?.accountManager.addOrUpdate(account)

        prepareSession(for: account)

        let payload: [AnyHashable: Any] = [
            "data": [
                "user": currentUserIdentifier.transportString(),
            ],
        ]

        // WHEN
        let pushCompleted1 = customExpectation(description: "Push completed 1")
        var userSession1: ZMUserSession!
        let pushCompleted2 = customExpectation(description: "Push completed 2")
        var userSession2: ZMUserSession!
        sessionManager?.processIncomingRealVoIPPush(payload: payload, completion: {
            pushCompleted1.fulfill()
            userSession1 = self.sessionManager!.backgroundUserSessions[account.userIdentifier]
        })
        sessionManager?.processIncomingRealVoIPPush(payload: payload, completion: {
            pushCompleted2.fulfill()
            userSession2 = self.sessionManager!.backgroundUserSessions[account.userIdentifier]
        })

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(userSession1)
        XCTAssertNotNil(userSession2)
        XCTAssertEqual(userSession1, userSession2)

        // CLEANUP
        sessionManager!.tearDownAllBackgroundSessions()
    }

    func setupSession() -> ZMUserSession {
        let manager = sessionManager!.accountManager
        let account = Account(userName: "Test Account", userIdentifier: currentUserIdentifier)
        manager.addOrUpdate(account)
        sessionManager!.environment.cookieStorage(for: account).authenticationCookieData = HTTPCookie.validCookieData()
        manager.addAndSelect(account)

        var session: ZMUserSession! = nil

        let sessionLoadExpectation = customExpectation(description: "Session loaded")
        sessionManager?.withSession(for: account, perform: { createdSession in
            session = createdSession
            sessionLoadExpectation.fulfill()
        })

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        let selfUser = ZMUser.selfUser(in: session.managedObjectContext)
        selfUser.remoteIdentifier = currentUserIdentifier
        session.managedObjectContext.saveOrRollback()

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        _ = createSelfClient(session.managedObjectContext)

        session.syncManagedObjectContext.performGroupedBlock {
            _ = ZMConversation.fetchOrCreate(
                with: self.currentUserIdentifier,
                domain: nil,
                in: session.syncManagedObjectContext
            )
            session.syncManagedObjectContext.saveOrRollback()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        return session
    }

    func testThatItConfiguresNotificationSettingsWhenAccountIsActivated() {
        // GIVEN
        _ = setupSession()
        let expectation = customExpectation(description: "Session loaded")
        sessionManager?.notificationCenter = notificationCenter!

        guard
            let sessionManager,
            let account = sessionManager.accountManager.account(with: currentUserIdentifier)
        else {
            return XCTFail()
        }

        // WHEN
        sessionManager.select(account, completion: { userSession in
            XCTAssertNotNil(userSession)
            expectation.fulfill()
        })

        wait(forConditionToBeTrue: self.sessionManager!.activeUserSession != nil, timeout: 5)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(
            notificationCenter?.registeredNotificationCategories,
            WireSyncEngine.PushNotificationCategory.allCategories
        )
        XCTAssertEqual(notificationCenter?.requestedAuthorizationOptions, [.alert, .badge, .sound])
        XCTAssertNotNil(notificationCenter?.delegate)

        // CLEANUP
        self.sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesTheAccountForPushReaction() {
        // GIVEN
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: crash at RequireString([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue],
        let session = setupSession()
        //        "Must call be called on the main queue.");
        session.isPerformingSync = false
        application?.applicationState = .background

        let selfConversation = ZMConversation.fetch(
            with: currentUserIdentifier,
            domain: nil,
            in: session.managedObjectContext
        )

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertNil(sessionManager!.activeUserSession)

        // WHEN
        sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleNotificationResponse(
                actionIdentifier: "",
                categoryIdentifier: category,
                userInfo: userInfo,
                completionHandler: {}
            )
        }

        wait(forConditionToBeTrue: self.sessionManager!.activeUserSession != nil, timeout: 5)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sessionManager!.activeUserSession, session)

        // CLEANUP
        sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesTheAccountForPushAction() {
        // GIVEN
        let session = setupSession()
        session.isPerformingSync = false
        application?.applicationState = .inactive

        let selfConversation = ZMConversation.fetch(
            with: currentUserIdentifier,
            domain: nil,
            in: session.managedObjectContext
        )

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertNil(sessionManager!.activeUserSession)

        // WHEN
        let completionExpectation = customExpectation(description: "Completed action")
        sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleNotificationResponse(
                actionIdentifier: "",
                categoryIdentifier: category,
                userInfo: userInfo,
                completionHandler: completionExpectation.fulfill
            )
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sessionManager!.activeUserSession, session)

        // CLEANUP
        sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItCallsForegroundNotificationResponderMethod() {
        // GIVEN
        let session = setupSession()
        session.isPerformingSync = false

        let responder = MockForegroundNotificationResponder()
        sessionManager?.foregroundNotificationResponder = responder

        let selfConversation = ZMConversation.fetch(
            with: currentUserIdentifier,
            domain: nil,
            in: session.managedObjectContext
        )

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = selfConversation?.remoteIdentifier
        userInfo.selfUserID = currentUserIdentifier

        let category = WireSyncEngine.PushNotificationCategory.conversation.rawValue

        XCTAssertTrue(responder.notificationPermissionRequests.isEmpty)

        // WHEN
        let completionExpectation = customExpectation(description: "Completed action")
        sessionManager?.handleNotification(with: userInfo) { userSession in
            userSession.handleInAppNotification(with: userInfo, categoryIdentifier: category) { _ in
                completionExpectation.fulfill()
            }
        }

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(responder.notificationPermissionRequests.count, 1)
        XCTAssertEqual(responder.notificationPermissionRequests.first!, selfConversation?.remoteIdentifier)

        // CLEANUP
        sessionManager!.tearDownAllBackgroundSessions()
    }

    func testThatItActivatesAccountWhichReceivesACallInTheBackground() {
        // GIVEN
        let manager = sessionManager!.accountManager
        let account1 = Account(userName: "Test Account 1", userIdentifier: currentUserIdentifier)
        sessionManager!.environment.cookieStorage(for: account1).authenticationCookieData = HTTPCookie.validCookieData()

        manager.addOrUpdate(account1)
        let account2 = Account(userName: "Test Account 2", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: account2).authenticationCookieData = HTTPCookie.validCookieData()
        manager.addOrUpdate(account2)

        // Make account 1 the active session
        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { session in
            session1 = session
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // Load session for account 2 in the background
        weak var session2: ZMUserSession?
        weak var conversation: ZMConversation?
        weak var caller: ZMUser?
        sessionManager!.withSession(for: account2, perform: { session in
            session2 = session
            conversation = ZMConversation.insertNewObject(in: session.managedObjectContext)
            caller = ZMUser.insertNewObject(in: session.managedObjectContext)
        })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // WHEN
        sessionManager?.callCenterDidChange(
            callState: .answered(degraded: false),
            conversation: conversation!,
            caller: caller!,
            timestamp: nil,
            previousCallState: nil
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sessionManager!.activeUserSession, session2)

        // CLEANUP
        sessionManager!.tearDownAllBackgroundSessions()
    }

    // the purpose of this test is to ensure push payloads can be processed in
    // the background as soon as the SessionManager is created
    func testThatABackgroundTaskCanBeCreatedAfterCreatingSessionManager() {
        // WHEN
        let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "PushActivity")

        // THEN
        XCTAssertNotNil(activity)
    }

    // MARK: Private

    // MARK: - Helpers

    private func createSelfClient(_ context: NSManagedObjectContext) -> UserClient {
        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = nil
        selfClient.user = ZMUser.selfUser(in: context)
        return selfClient
    }
}
