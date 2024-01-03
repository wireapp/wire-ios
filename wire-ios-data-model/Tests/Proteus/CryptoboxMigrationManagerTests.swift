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

@testable import WireDataModel
@testable import WireDataModelSupport

class CryptoboxMigrationManagerTests: ZMBaseManagedObjectTest {

    var sut: CryptoboxMigrationManager!
    var mockFileManager: MockFileManagerInterface!
    var proteusViaCoreCryptoFlag: DeveloperFlag!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!

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

        syncMOC.performAndWait({
            syncMOC.proteusService = nil
        })

        proteusViaCoreCryptoFlag.isOn = false
        DeveloperFlag.storage = UserDefaults.standard

        super.tearDown()
    }

    var accountDirectory: URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("CryptoBoxMigrationManagerTests")
    }

    lazy var cryptoboxDirectory = accountDirectory.appendingPathComponent("otr")

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

    func test_itPerformsMigrations() throws {
        // Given
        let migrated = expectation(description: "Cryptobox was migrated")
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = true
        mockSafeCoreCrypto.coreCrypto.mockProteusCryptoboxMigrate = { _ in
            migrated.fulfill()
        }

        // When
        do {
            try sut.performMigration(accountDirectory: accountDirectory, coreCrypto: mockSafeCoreCrypto)
        } catch {
            XCTFail("failed to perform migration: \(error.localizedDescription)")
        }

        // Then
        XCTAssertEqual(mockFileManager.removeItemAt_Invocations, [cryptoboxDirectory])
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_itDoesNotPerformMigration_CoreCryptoError() {
        // Given
        mockFileManager.fileExistsAtPath_MockValue = true
        proteusViaCoreCryptoFlag.isOn = true

        mockSafeCoreCrypto.coreCrypto.mockProteusCryptoboxMigrate = { _ in
            throw CryptoboxMigrationManager.Failure.failedToMigrateData
        }

        // When
        XCTAssertThrowsError(try sut.performMigration(accountDirectory: accountDirectory, coreCrypto: mockSafeCoreCrypto)) { error in
            XCTAssertEqual(error as? CryptoboxMigrationManager.Failure, CryptoboxMigrationManager.Failure.failedToMigrateData)
        }

        // Then
        XCTAssertTrue(mockFileManager.removeItemAt_Invocations.isEmpty)
    }
}
