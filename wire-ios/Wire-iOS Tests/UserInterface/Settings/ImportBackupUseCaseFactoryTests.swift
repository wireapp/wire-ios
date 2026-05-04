//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireFoundation
import WireFoundationSupport
import WireSettingsUI
import WireSyncEngine
import XCTest

@testable import Wire

final class ImportBackupUseCaseFactoryTests: XCTestCase {

    private var useCaseMock: ImportBackupUseCaseProtocolMock!
    private var legacyUseCaseMock: ImportBackupUseCaseProtocolMock!
    private var sut: ImportBackupUseCaseFactory!

    override func setUp() {
        useCaseMock = ImportBackupUseCaseProtocolMock()
        useCaseMock.isImportDestructive = false

        legacyUseCaseMock = ImportBackupUseCaseProtocolMock()
        legacyUseCaseMock.isImportDestructive = true

        sut = ImportBackupUseCaseFactory(
            importBackupUseCase: { [useCaseMock] _ in useCaseMock! },
            legacyImportBackupUseCase: { [legacyUseCaseMock] _ in legacyUseCaseMock! }
        )
    }

    override func tearDown() {
        sut = nil
        legacyUseCaseMock = nil
        useCaseMock = nil
    }

    func testUseCaseIsReturned() throws {
        // Given
        let fileExtension = "wbu"
        let backupFile = URL(filePath: "backup.\(fileExtension)", directoryHint: .notDirectory)

        // When
        let useCaseImplementation = try sut.importBackupUseCase(for: backupFile)

        // Then
        XCTAssertFalse(useCaseImplementation.isImportDestructive)
    }

    func testLegacyUseCaseIsReturned() async throws {
        // Given
        let fileExtensions = ["ios_wbu", "ios-wbu"]
        for fileExtension in fileExtensions {
            let backupFile = URL(filePath: "backup.\(fileExtension)", directoryHint: .notDirectory)

            // When
            let useCaseImplementation = try sut.importBackupUseCase(for: backupFile)

            // Then
            XCTAssertTrue(useCaseImplementation.isImportDestructive)
        }
    }

    func testUnknownFileExtensionsThrow() async throws {
        #if true // TODO: [WPB-17397] re-enable after fixing duplicate symbols
            throw XCTSkip("disabled because catch is not entered")
        #else
            // Given
            let fileExtension = "zip"
            let backupFile = URL(filePath: "backup.\(fileExtension)", directoryHint: .notDirectory)

            // When
            XCTAssertThrowsError(try sut.importBackupUseCase(for: backupFile)) { error in

                // Then
                guard case ImportBackupError.invalidFileExtension = error else {
                    return XCTFail("unexpected error: \(error)")
                }
            }
        #endif
    }

}
