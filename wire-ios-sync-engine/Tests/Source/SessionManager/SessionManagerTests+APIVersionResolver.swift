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

import WireTesting
import XCTest
@testable import WireSyncEngine

final class SessionManagerAPIVersionResolverTests: IntegrationTest {
    func testThatDatabaseIsMigrated_WhenFederationIsEnabled() throws {
        // GIVEN

        // Setup Session Manager
        let sessionManager = try XCTUnwrap(sessionManager)
        let account = addAccount(name: "John Doe", userIdentifier: UUID())
        sessionManager.accountManager.select(account)

        // Load session
        var session: ZMUserSession!
        sessionManager.loadSession(for: account, completion: {
            session = $0
        })

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let userRemoteIdentifier = UUID()
        let conversationRemoteIdentifier = UUID()
        // Create user and conversation
        session.syncContext.performAndWait {
            let user = ZMUser.insertNewObject(in: session.syncContext)
            let conversation = ZMConversation.insertNewObject(in: session.syncContext)
            user.remoteIdentifier = userRemoteIdentifier
            conversation.remoteIdentifier = conversationRemoteIdentifier

            XCTAssertNil(user.domain)
            XCTAssertNil(conversation.domain)
        }

        // Setup domain
        let domain = "example.domain.com"
        BackendInfo.domain = domain

        // Setup expectation & Session Manager delegate
        let expectation = XCTestExpectation(description: "Migration completed")
        let delegate = MockSessionManagerExpectationDelegate()
        delegate.expectation = expectation
        sessionManager.delegate = delegate

        // WHEN
        sessionManager.apiVersionResolverDetectedFederationHasBeenEnabled()

        // THEN
        XCTAssertTrue(delegate.didCallWillMigrateAccount)

        wait(for: [expectation], timeout: 5)

        XCTAssertTrue(delegate.didCallDidPerformFederationMigration)
        XCTAssertTrue(delegate.didCallDidChangeActiveUserSession)
        let newSession = try XCTUnwrap(delegate.session)

        newSession.syncContext.performAndWait {
            let migratedUser = ZMUser.fetch(with: userRemoteIdentifier, domain: domain, in: newSession.syncContext)
            XCTAssertNotNil(migratedUser)
            XCTAssertEqual(migratedUser?.domain, domain)
        }

        newSession.syncContext.performAndWait {
            let migratedConversation = ZMConversation.fetch(
                with: conversationRemoteIdentifier,
                domain: domain,
                in: newSession.syncContext
            )
            XCTAssertNotNil(migratedConversation)
            XCTAssertEqual(migratedConversation?.domain, domain)
        }
        userSession = nil
    }
}

private class MockSessionManagerExpectationDelegate: SessionManagerDelegate {
    var didCallDidPerformFederationMigration = false
    var expectation: XCTestExpectation?
    func sessionManagerDidPerformFederationMigration(activeSession: UserSession?) {
        didCallDidPerformFederationMigration = true
        expectation?.fulfill()
    }

    var didCallWillMigrateAccount = false
    func sessionManagerWillMigrateAccount(userSessionCanBeTornDown: @escaping () -> Void) {
        didCallWillMigrateAccount = true
        userSessionCanBeTornDown()
    }

    var didCallDidChangeActiveUserSession = false
    var session: ZMUserSession?
    func sessionManagerDidChangeActiveUserSession(userSession: ZMUserSession) {
        didCallDidChangeActiveUserSession = true
        session = userSession
    }

    func sessionManagerDidReportLockChange(forSession session: UserSession) {
        // no op
    }

    func sessionManagerDidFailToLogin(error: Error?) {
        // no op
    }

    func sessionManagerWillLogout(error: Error?, userSessionCanBeTornDown: (() -> Void)?) {
        // no op
    }

    func sessionManagerWillOpenAccount(
        _ account: Account,
        from selectedAccount: Account?,
        userSessionCanBeTornDown: @escaping () -> Void
    ) {
        userSessionCanBeTornDown()
    }

    func sessionManagerDidFailToLoadDatabase(error: Error) {
        // no op
    }

    func sessionManagerDidBlacklistCurrentVersion(reason: BlacklistReason) {
        // no op
    }

    func sessionManagerDidBlacklistJailbrokenDevice() {
        // no op
    }

    func sessionManagerRequireCertificateEnrollment() {
        // no-op
    }

    func sessionManagerDidEnrollCertificate(for activeSession: UserSession?) {
        // no-op
    }

    func sessionManagerDidPerformAPIMigrations(activeSession: UserSession?) {
        // no op
    }

    public func sessionManagerAsksToRetryStart() {
        // no op
    }

    func sessionManagerDidCompleteInitialSync(for activeSession: WireSyncEngine.UserSession?) {
        // no op
    }

    var isInAuthenticatedAppState: Bool {
        true
    }

    var isInUnathenticatedAppState: Bool {
        false
    }
}
