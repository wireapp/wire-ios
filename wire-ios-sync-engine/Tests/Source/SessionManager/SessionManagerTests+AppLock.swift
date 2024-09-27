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

final class SessionManagerAppLockTests: IntegrationTest {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        // Mock transport doesn't support multiple accounts at the moment so we pretend to be offline
        // in order to avoid the user session's getting stuck in a request loop.
        mockTransportSession.doNotRespondToRequests = true
        appLock = MockAppLock()
    }

    override func tearDown() {
        sessionManager!.tearDownAllBackgroundSessions()
        appLock = nil
        mockTransportSession.doNotRespondToRequests = false
        super.tearDown()
    }

    func test_ItBeginsAppLockTimer_WhenChangingTheActiveUserSession() {
        // Given
        let account1 = addAccount(name: "Account 1", userIdentifier: currentUserIdentifier)
        let account2 = addAccount(name: "Account 2", userIdentifier: .create())

        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { session in
            session1 = session
            session1?.appLockController = self.appLock
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // When
        let switchedAccount = customExpectation(description: "switched account")
        sessionManager?.select(account2, completion: { _ in
            switchedAccount.fulfill()
        }, tearDownCompletion: nil)

        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))

        // Then
        XCTAssertEqual(appLock.methodCalls.beginTimer.count, 1)
    }

    func test_ItBeginAppLockTimer_WhenTheAppResignsActive() {
        // Given
        let account1 = addAccount(name: "Account 1", userIdentifier: currentUserIdentifier)

        // Make account 1 the active session.
        weak var session1: ZMUserSession?
        sessionManager?.loadSession(for: account1, completion: { session in
            session1 = session
            session1?.appLockController = self.appLock
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(sessionManager!.activeUserSession, session1)

        // When
        let notification = Notification(name: UIApplication.willResignActiveNotification)
        sessionManager!.applicationWillResignActive(notification)

        // Then
        XCTAssertEqual(appLock.methodCalls.beginTimer.count, 1)
    }

    // MARK: Private

    private var appLock: MockAppLock!
}
