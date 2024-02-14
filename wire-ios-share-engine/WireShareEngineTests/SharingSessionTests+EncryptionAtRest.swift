//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import XCTest
import LocalAuthentication
import WireDataModel
@testable import WireShareEngine

final class SharingSessionTestsEncryptionAtRest: BaseSharingSessionTests {

    // MARK: - Life Cycle

    override func tearDown() {
        try? sharingSession.earService.disableEncryptionAtRest(
            context: sharingSession.userInterfaceContext,
            skipMigration: true
        )

        super.tearDown()
    }

    // MARK: - Database locking/unlocking

    func testThatDatabaseIsUnlocked_WhenEncryptionAtRestIsDisabled() {
        // given
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(sharingSession.isDatabaseLocked)
    }

    func testThatDatabaseIsLocked_BeforeUnlockingDatabase() throws {
        // given
        try sharingSession.earService.enableEncryptionAtRest(
            context: sharingSession.userInterfaceContext,
            skipMigration: true
        )

        sharingSession.earService.lockDatabase()

        // then
        XCTAssertTrue(sharingSession.isDatabaseLocked)
    }

    func testThatDatabaseIsUnlocked_AfterUnlockingDatabase() throws {
        // given
        try sharingSession.earService.enableEncryptionAtRest(
            context: sharingSession.userInterfaceContext,
            skipMigration: true
        )

        sharingSession.earService.lockDatabase()
        XCTAssertTrue(sharingSession.isDatabaseLocked)

        // when
        let context = LAContext()
        try sharingSession.unlockDatabase(with: context)

        // then
        XCTAssertFalse(sharingSession.isDatabaseLocked)
    }

}
