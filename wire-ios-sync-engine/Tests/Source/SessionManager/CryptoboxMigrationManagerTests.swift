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

import Foundation
import XCTest
import WireTransport
@testable import WireSyncEngine

class CryptoboxMigrationManagerTests: MessagingTest {

    var sut: CryptoboxMigrationManager?
    var proteusViaCoreCryptoFlag = DeveloperFlag.proteusViaCoreCrypto

    override func setUp() {
        sut = CryptoboxMigrationManager()
        super.setUp()
    }

    override func tearDown() {
        sut = nil
        proteusViaCoreCryptoFlag.isOn = false
        super.tearDown()
    }

    // MARK: - Verifying if migration is needed

    func test_itReturnsTrue_WhenMigrationIsNeeded() {
        // Given
        let cryptoboxDirectory = FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))

        // When
        proteusViaCoreCryptoFlag.isOn = true

        // Then
        XCTAssertTrue(sut!.isNeeded(in: accountDirectory))
    }

    func test_itReturnsFalse_WhenMigrationIsNotNeeded_ProteusViaCoreCryptoFlagIsDisabled() {
        // Given
        let cryptoboxDirectory = FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))

        // When
        proteusViaCoreCryptoFlag.isOn = false

        // Then
        XCTAssertFalse(sut!.isNeeded(in: accountDirectory))
    }

    func test_itReturnsFalse_WhenMigrationIsNotNeeded_AccountDirectoryDoesNotExist() {
        // Given
        let fakeAccountDirectory: URL = URL(fileURLWithPath: "something")

        // When
        proteusViaCoreCryptoFlag.isOn = true

        // Then
        XCTAssertFalse(sut!.isNeeded(in: fakeAccountDirectory))
    }

    // MARK: - Perform migration

    func test_itPerformsMigrations() {
        // Given
        let cryptoboxDirectory = FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))

        // When
        proteusViaCoreCryptoFlag.isOn = true
        syncMOC.proteusService = mockProteusService(with: nil)
        try? sut?.perform(in: accountDirectory, syncContext: syncMOC)

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))
    }

    func test_itDoesNotPerformMigration_CoreCryptoError() {
        // Given
        let cryptoboxDirectory = FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))

        // When
        proteusViaCoreCryptoFlag.isOn = true
        syncMOC.proteusService = mockProteusService(with: CryptoboxMigrationError.failedToMigrateData)

        XCTAssertThrowsError(try sut?.perform(in: accountDirectory, syncContext: syncMOC)) { error in
            XCTAssertEqual(error as? CryptoboxMigrationError, CryptoboxMigrationError.failedToMigrateData)
        }

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: cryptoboxDirectory.path))
    }

    // MARK: - Helpers

    private func mockProteusService(with error: Error?) -> MockProteusServiceInterface {
        let proteusService = MockProteusServiceInterface()

        if let migrationError = error {
            proteusService.migrateCryptoboxSessions_MockError = migrationError
        }
        proteusService.migrateCryptoboxSessions_MockMethod = { _ in }

        return proteusService
    }

}
