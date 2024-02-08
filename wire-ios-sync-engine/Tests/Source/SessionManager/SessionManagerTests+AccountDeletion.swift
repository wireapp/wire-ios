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

final class SessionManagertests_AccountDeletion: IntegrationTest {

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
        let account = self.createAccount()

        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

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

        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else { return XCTFail() }

        let account = sessionManager!.accountManager.selectedAccount!
        let accountFolder = CoreDataStack.accountDataFolder(accountIdentifier: account.userIdentifier, applicationContainer: sharedContainer)

        // when
        performIgnoringZMLogError {
            self.sessionManager!.delete(account: account)
        }

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

        // then
        XCTAssertNil(repository.fetchLastEventID())
    }

}
