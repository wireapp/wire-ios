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

final class SessionManagerAuthenticationFailureTests: IntegrationTest {
    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItDeletesTheCookie_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        XCTAssertTrue(sessionManager!.isSelectedAccountAuthenticated)

        // when
        let account = sessionManager!.accountManager.selectedAccount!
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .accessTokenExpired, userInfo: nil),
            accountId: account.userIdentifier
        )

        // then
        XCTAssertFalse(sessionManager!.isSelectedAccountAuthenticated)
    }

    func testThatItDeletesAccount_IfRemoteClientIsDeleted() {
        // given
        XCTAssertTrue(login())
        let account = sessionManager!.accountManager.selectedAccount!

        // when
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .clientDeletedRemotely, userInfo: nil),
            accountId: account.userIdentifier
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else { return XCTFail() }
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: account.userIdentifier,
            applicationContainer: sharedContainer
        )

        XCTAssertFalse(FileManager.default.fileExists(atPath: accountFolder.path))
    }

    func testThatItTearsDownActiveUserSession_OnAuthentictionFailure() {
        // given
        XCTAssert(login())
        XCTAssertNotNil(sessionManager?.activeUserSession)

        // when
        let account = sessionManager!.accountManager.selectedAccount!
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .accessTokenExpired, userInfo: nil),
            accountId: account.userIdentifier
        )

        // then
        XCTAssertNil(sessionManager?.activeUserSession)
    }

    func testThatItTearsDownBackgroundUserSession_OnAuthentictionFailure() {
        // given
        let additionalAccount = Account(userName: "Additional Account", userIdentifier: UUID())
        sessionManager!.environment.cookieStorage(for: additionalAccount).authenticationCookieData = HTTPCookie
            .validCookieData()
        sessionManager!.accountManager.addOrUpdate(additionalAccount)

        XCTAssert(login())
        XCTAssertNotNil(sessionManager?.activeUserSession)

        // load additional account as a background session
        sessionManager!.withSession(for: additionalAccount, perform: { _ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertNotNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])

        // when
        sessionManager?.authenticationInvalidated(
            NSError(userSessionErrorCode: .accessTokenExpired, userInfo: nil),
            accountId: additionalAccount.userIdentifier
        )

        // then
        XCTAssertNil(sessionManager?.backgroundUserSessions[additionalAccount.userIdentifier])
    }
}
