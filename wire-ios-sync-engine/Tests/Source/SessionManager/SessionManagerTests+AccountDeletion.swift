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

// MARK: - SessionManagerAccountDeletionTests

final class SessionManagerAccountDeletionTests: IntegrationTest {
    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesTheAccountFolder_WhenDeletingAccountWithoutActiveUserSession() throws {
        // given
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail()
            return
        }
        let account = createAccount()

        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        try FileManager.default.createDirectory(at: accountFolder, withIntermediateDirectories: true, attributes: nil)

        // when
        performIgnoringZMLogError {
            self.sessionManager!.delete(account: account)
        }

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccountFolder_WhenDeletingActiveUserSessionAccount() throws {
        // given
        XCTAssert(login())

        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }

        let account = sessionManager!.accountManager.selectedAccount!
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        // when
        performIgnoringZMLogError {
            self.sessionManager!.delete(account: account)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheLastEventID_WhenDeletingActiveUserSessionAccount() throws {
        // given
        XCTAssert(login())

        let sessionManager = try XCTUnwrap(sessionManager)
        let account = try XCTUnwrap(sessionManager.accountManager.selectedAccount)
        let repository = LastEventIDRepository(
            userID: account.userIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )
        XCTAssertNotNil(repository.fetchLastEventID())

        // when
        performIgnoringZMLogError {
            sessionManager.delete(account: account)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(repository.fetchLastEventID())
    }
}

// MARK: - SessionManagerTests_PasswordVerificationFailure_With_DeleteAccountAfterThreshold

class SessionManagerTests_PasswordVerificationFailure_With_DeleteAccountAfterThreshold: IntegrationTest {
    // MARK: Internal

    override var sessionManagerConfiguration: SessionManagerConfiguration {
        SessionManagerConfiguration(failedPasswordThresholdBeforeWipe: threshold)
    }

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesAccount_IfLimitIsReached() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.passwordVerificationDidFail(with: threshold!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDoesntDeleteAccount_IfLimitIsNotReached() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.passwordVerificationDidFail(with: threshold! - 1)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    // MARK: Private

    private var threshold: Int? = 2
}

// MARK: - SessionManagerTests_AuthenticationFailure_With_DeleteAccountOnAuthentictionFailure

class SessionManagerTests_AuthenticationFailure_With_DeleteAccountOnAuthentictionFailure: IntegrationTest {
    override var sessionManagerConfiguration: SessionManagerConfiguration {
        SessionManagerConfiguration(wipeOnCookieInvalid: true)
    }

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesTheAccount_OnLaunchIfAccessTokenHasExpired() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        deleteAuthenticationCookie()
        recreateSessionManager()

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccount_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .accessTokenExpired, userInfo: nil),
            accountId: account.userIdentifier
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItDeletesTheAccount_OnAuthentictionFailureForBackgroundSession() {
        // given
        let additionalAccount = Account(userName: "Additional Account", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: additionalAccount).authenticationCookieData = HTTPCookie
            .validCookieData()
        sessionManager!.accountManager.addOrUpdate(additionalAccount)

        XCTAssert(login())

        XCTAssertNotNil(sessionManager?.activeUserSession)

        // load additional account as a background session
        let sessionLoaded = customExpectation(description: "Background session loaded")
        sessionManager?.withSession(for: additionalAccount, perform: { _ in
            sessionLoaded.fulfill()
        })
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNotNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])

        // when
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .accessTokenExpired, userInfo: nil),
            accountId: additionalAccount.userIdentifier
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: additionalAccount.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }
}
