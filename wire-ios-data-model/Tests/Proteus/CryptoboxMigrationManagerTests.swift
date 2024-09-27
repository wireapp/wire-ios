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
import WireTransport
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

class CryptoboxMigrationManagerTests: ZMBaseManagedObjectTest {
    var sut: CryptoboxMigrationManager!
    var mockFileManager: MockFileManagerInterface!
    var proteusViaCoreCryptoFlag: DeveloperFlag!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!

    lazy var cryptoboxDirectory = accountDirectory.appendingPathComponent("otr")

    var accountDirectory: URL {
        FileManager.default
            .temporaryDirectory
            .appendingPathComponent("CryptoBoxMigrationManagerTests")
    }

    override func setUp() {
        super.setUp()
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        proteusViaCoreCryptoFlag = .proteusViaCoreCrypto

        mockFileManager = MockFileManagerInterface()
        mockFileManager.cryptoboxDirectoryIn_MockValue = cryptoboxDirectory
        mockFileManager.removeItemAt_MockMethod = { _ in }
        mockSafeCoreCrypto = MockSafeCoreCrypto()
        sut = CryptoboxMigrationManager(fileManager: mockFileManager)
    }

    override func tearDown() {
        sut = nil
        mockFileManager = nil
        mockSafeCoreCrypto = nil

        syncMOC.performAndWait {
            syncMOC.proteusService = nil
        }

        proteusViaCoreCryptoFlag.isOn = false
        DeveloperFlag.storage = UserDefaults.standard

        super.tearDown()
    }

    // MARK: - Verifying if migration is needed

    func test_IsMigrationNeeded_FilesExistAndFlagIsOn() {
        // Given
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = true

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertTrue(result)
    }

    func test_IsMigrationNeeded_FilesExistAndFlagIsOff() {
        // Given
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = false

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertFalse(result)
    }

    func test_IsMigrationNeeded_FilesDoNotExistAndFlagIsOn() {
        // Given
        mockFileManager.fileExistsAtPath_MockValue = false
        proteusViaCoreCryptoFlag.isOn = true

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Perform migration

    func test_itPerformsMigrations() async throws {
        // Given
        let migrated = customExpectation(description: "Cryptobox was migrated")
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = true
        mockSafeCoreCrypto.coreCrypto.proteusCryptoboxMigratePath_MockMethod = { _ in
            migrated.fulfill()
        }

        // When
        try await sut.performMigration(accountDirectory: accountDirectory, coreCrypto: mockSafeCoreCrypto)

        // Then
        XCTAssertEqual(mockFileManager.removeItemAt_Invocations, [cryptoboxDirectory])
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itDoesNotPerformMigration_CoreCryptoError() async {
        // Given
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = true

        mockSafeCoreCrypto.coreCrypto.proteusCryptoboxMigratePath_MockMethod = { _ in
            throw CryptoboxMigrationManager.Failure.failedToMigrateData
        }

        // When
        await assertItThrows(error: CryptoboxMigrationManager.Failure.failedToMigrateData) {
            try await self.sut.performMigration(
                accountDirectory: self.accountDirectory,
                coreCrypto: self.mockSafeCoreCrypto
            )
        }

        // Then
        XCTAssertTrue(mockFileManager.removeItemAt_Invocations.isEmpty)
    }
}
