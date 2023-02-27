//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireTesting
@testable import WireSyncEngine

class CryptoboxMigrationMock: CryptoboxMigration {

    var needsMigration: Bool = true
    var performCallCount: UInt = 0

    func isNeeded(in accountDirectory: URL) -> Bool {
        return needsMigration
    }

    func perform(in accountDirectory: URL, syncContext: NSManagedObjectContext) {
        performCallCount += 1
    }

}

class SessionManagerTests_CryptoboxMigration: IntegrationTest {

    var proteusViaCoreCryptoFlag = DeveloperFlag.proteusViaCoreCrypto
    var cryptoboxMigrationMock: CryptoboxMigrationMock?

    override func setUp() {
        super.setUp()
        cryptoboxMigrationMock = CryptoboxMigrationMock()
        createSelfUserAndConversation()
    }

    override func tearDown() {
        cryptoboxMigrationMock = nil
        proteusViaCoreCryptoFlag.isOn = false
        super.tearDown()
    }

    func testItPerformsMigrationIfNeeded() {
        // Given
        sessionManager?.cryptoboxMigrationManager = cryptoboxMigrationMock!
        cryptoboxMigrationMock?.needsMigration = true

        // When
        XCTAssert(login())

        // Then
        XCTAssertEqual(cryptoboxMigrationMock?.performCallCount, 1)
    }

    func testItDoesNotPerformMigration() {
        // Given
        sessionManager?.cryptoboxMigrationManager = cryptoboxMigrationMock!
        cryptoboxMigrationMock?.needsMigration = false

        // When
        XCTAssert(login())

        // Then
        XCTAssertEqual(cryptoboxMigrationMock?.performCallCount, 0)
    }
    
}
