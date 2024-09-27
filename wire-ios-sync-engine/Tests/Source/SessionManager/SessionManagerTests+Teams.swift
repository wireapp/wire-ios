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

final class SessionManagerTeamsTests: IntegrationTest {
    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
    }

    func testThatItUpdatesAccountAfterLoginWithTeamName() {
        // given
        let teamName = "Wire"
        let image = MockAsset(
            in: mockTransportSession.managedObjectContext,
            forID: selfUser.previewProfileAssetIdentifier!
        )
        mockTransportSession.performRemoteChanges { session in
            let team = session.insertTeam(withName: teamName, isBound: true, users: [self.selfUser])
            team.creator = self.selfUser
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        _ = MockAsset(in: mockTransportSession.managedObjectContext, forID: selfUser.previewProfileAssetIdentifier!)

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first,
              manager.accounts.count == 1 else {
            XCTFail("Should have one account"); return
        }
        XCTAssertEqual(account.userIdentifier.transportString(), selfUser.identifier)
        XCTAssertEqual(account.teamName, teamName)
        XCTAssertEqual(account.imageData, image?.data)
        XCTAssertNil(account.teamImageData)
        XCTAssertEqual(account.loginCredentials, selfUser.loginCredentials)
    }

    func testThatItUpdatesAccountWithUserDetailsAfterLogin() {
        // when
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first,
              manager.accounts.count == 1 else {
            XCTFail("Should have one account"); return
        }
        XCTAssertEqual(account.userIdentifier.transportString(), selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, selfUser.name)
        let image = MockAsset(
            in: mockTransportSession.managedObjectContext,
            forID: selfUser.previewProfileAssetIdentifier!
        )

        XCTAssertEqual(account.imageData, image?.data)
    }

    func testThatItUpdatesAccountWithUserDetailsAfterLoginIntoExistingAccount() {
        // given
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        sessionManager?.logoutCurrentSession()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        closePushChannelAndWaitUntilClosed()
        XCTAssert(login())

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first,
              manager.accounts.count == 1 else {
            XCTFail("Should have one account"); return
        }
        XCTAssertEqual(account.userIdentifier.transportString(), selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, selfUser.name)
        let image = MockAsset(
            in: mockTransportSession.managedObjectContext,
            forID: selfUser.previewProfileAssetIdentifier!
        )

        XCTAssertEqual(account.imageData, image?.data)
    }

    func testThatItUpdatesAccountAfterUserNameChange() {
        // when
        XCTAssert(login())

        let newName = "BOB"
        mockTransportSession.performRemoteChanges { _ in
            self.selfUser.name = newName
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else {
            return XCTFail()
        }
        let manager = AccountManager(sharedDirectory: sharedContainer)
        guard let account = manager.accounts.first,
              manager.accounts.count == 1 else {
            XCTFail("Should have one account"); return
        }
        XCTAssertEqual(account.userIdentifier.transportString(), selfUser.identifier)
        XCTAssertNil(account.teamName)
        XCTAssertEqual(account.userName, selfUser.name)
    }

    func testThatItSendsAuthenticationErrorWhenAccountLimitIsReached() throws {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())
        let account3 = Account(userName: "Account 3", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)
        sessionManager?.accountManager.addOrUpdate(account2)
        sessionManager?.accountManager.addOrUpdate(account3)

        // when
        XCTAssert(login(ignoreAuthenticationFailures: true))

        // then
        guard
            let delegate = mockLoginDelegete,
            let error = delegate.currentError
        else {
            return XCTFail()
        }

        XCTAssertTrue(delegate.didCallAuthenticationDidFail)
        XCTAssertEqual(error, NSError(userSessionErrorCode: .accountLimitReached, userInfo: nil))
    }

    func testThatItChecksAccountsForExistingAccount() {
        // given
        let account1 = Account(userName: "Account 1", userIdentifier: UUID.create())
        let account2 = Account(userName: "Account 2", userIdentifier: UUID.create())

        sessionManager?.accountManager.addOrUpdate(account1)

        // then
        XCTAssertTrue(sessionManager!.session(session: unauthenticatedSession!, isExistingAccount: account1))
        XCTAssertFalse(sessionManager!.session(session: unauthenticatedSession!, isExistingAccount: account2))
    }
}
