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

class CryptoboxMigrationManagerTests: ZMBaseManagedObjectTest {

    var sut: CryptoboxMigrationManager!
    var fileManagerMock: FileManagerMock!
    var proteusViaCoreCryptoFlag = DeveloperFlag.proteusViaCoreCrypto
    var mockProteusService: MockProteusServiceInterface!

    override func setUp() {
        super.setUp()
        fileManagerMock = FileManagerMock(cryptoboxDirectory: cryptoboxDirectory)
        sut = CryptoboxMigrationManager(fileManager: fileManagerMock)
        mockProteusService = MockProteusServiceInterface()
        syncMOC.proteusService = mockProteusService
    }

    override func tearDown() {
        sut = nil
        fileManagerMock = nil
        mockProteusService = nil
        proteusViaCoreCryptoFlag.isOn = false
        syncMOC.proteusService = nil
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
        fileManagerMock.cryptoboxFilesExist = true
        proteusViaCoreCryptoFlag.isOn = true

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertTrue(result)
    }

    func test_IsMigrationNeeded_FilesExistAndFlagIsOff() {
        // Given
        fileManagerMock.cryptoboxFilesExist = true
        proteusViaCoreCryptoFlag.isOn = false

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertFalse(result)
    }

    func test_IsMigrationNeeded_FilesDoNotExistAndFlagIsOn() {
        // Given
        fileManagerMock.cryptoboxFilesExist = false
        proteusViaCoreCryptoFlag.isOn = true

        // When
        let result = sut.isMigrationNeeded(accountDirectory: accountDirectory)

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Perform migration

    func test_itPerformsMigrations() throws {
        // Given
        fileManagerMock.cryptoboxFilesExist = true
        proteusViaCoreCryptoFlag.isOn = true

        mockProteusService.migrateCryptoboxSessionsAt_MockMethod = { _ in }

        // When
        try sut.performMigration(accountDirectory: accountDirectory, syncContext: syncMOC)

        // Then
        XCTAssertEqual(fileManagerMock.removeItemInvocations, [cryptoboxDirectory])
        XCTAssertEqual(mockProteusService.migrateCryptoboxSessionsAt_Invocations.count, 1)
    }

    func test_itDoesNotPerformMigration_CoreCryptoError() {
        // Given
        fileManagerMock.cryptoboxFilesExist = true
        proteusViaCoreCryptoFlag.isOn = true

        mockProteusService.migrateCryptoboxSessionsAt_MockError = CryptoboxMigrationManager.Failure.failedToMigrateData

        // When
        XCTAssertThrowsError(try sut.performMigration(accountDirectory: accountDirectory, syncContext: syncMOC)) { error in
            XCTAssertEqual(error as? CryptoboxMigrationManager.Failure, CryptoboxMigrationManager.Failure.failedToMigrateData)
        }

        // Then
        XCTAssertTrue(fileManagerMock.removeItemInvocations.isEmpty)
    }

    // MARK: - Complete migration

    func test_itCompletesMigration() throws {
        // Given
        mockProteusService.completeInitialization_MockMethod = {}

        // When
        try sut.completeMigration(syncContext: syncMOC)

        // Then
        XCTAssertEqual(mockProteusService.completeInitialization_Invocations.count, 1)
    }

}

class FileManagerMock: FileManagerInterface {

    init(cryptoboxDirectory: URL) {
        self.cryptoboxDirectory = cryptoboxDirectory
    }

    var cryptoboxFilesExist = false

    func fileExists(atPath path: String) -> Bool {
        return cryptoboxFilesExist
    }

    var removeItemInvocations = [URL]()

    func removeItem(at url: URL) throws {
        removeItemInvocations.append(url)
    }

    var cryptoboxDirectory: URL

    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        return cryptoboxDirectory
    }

}
