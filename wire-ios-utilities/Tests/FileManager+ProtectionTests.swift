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
import XCTest

class FileManagerProtectionTests: XCTestCase {
    var fileManager: FileManagerThatRecordsFileProtectionAttributes!

    override func setUp() {
        fileManager = FileManagerThatRecordsFileProtectionAttributes()
        wipeTestFolder()
    }

    override func tearDown() {
        fileManager = nil
        wipeTestFolder()
    }
}

// MARK: - Create and protect

extension FileManagerProtectionTests {
    func testThatItCreatesAndProtectedFolder() throws {
        // GIVEN
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFolder.path))

        // WHEN
        try fileManager.createAndProtectDirectory(at: testFolder)

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFolder.path))
        XCTAssertTrue(try existingLocalURLIsExcludedFromBackup(testFolder))
        XCTAssertTrue(fileManager.isFileProtectedUntilFirstUnlock(testFolder))
    }

    func testThatItCreatesAndProtectsAnAlreadyExistingFolder() throws {
        // GIVEN
        try createTestFolder()

        // WHEN
        try fileManager.createAndProtectDirectory(at: testFolder)

        // THEN
        XCTAssertTrue(try existingLocalURLIsExcludedFromBackup(testFolder))
        XCTAssertTrue(fileManager.isFileProtectedUntilFirstUnlock(testFolder))
    }
}

// MARK: - Backup exclusion

extension FileManagerProtectionTests {
    func testThatItCreatesAndExcludesAFolderFromBackup() throws {
        // GIVEN
        try createTestFolder()

        // WHEN
        try! testFolder.excludeFromBackup()

        // THEN
        XCTAssertTrue(try existingLocalURLIsExcludedFromBackup(testFolder))
    }

    func testThatItDetectsExcludedFromBackup() throws {
        // GIVEN
        try fileManager.createAndProtectDirectory(at: testFolder)

        // THEN
        XCTAssertTrue(testFolder.isExcludedFromBackup)
    }

    func testThatEmptyFolderIsNotExcludedFromBackup() {
        XCTAssertFalse(testFolder.isExcludedFromBackup)
    }

    func testThatNonExcludedFolderIsNotExcludedFromBackup() throws {
        // GIVEN
        try createTestFolder()

        // THEN
        XCTAssertFalse(testFolder.isExcludedFromBackup)
    }
}

// MARK: - Protection until unlocked

extension FileManagerProtectionTests {
    func testThatItProtectsAFolder() throws {
        // GIVEN
        try createTestFolder()

        // WHEN
        try fileManager.setProtectionUntilFirstUserAuthentication(testFolder)

        // THEN
        XCTAssertTrue(fileManager.isFileProtectedUntilFirstUnlock(testFolder))
    }
}

// MARK: - Helpers

extension FileManagerProtectionTests {
    func createTestFolder() throws {
        try fileManager.createDirectory(at: testFolder, withIntermediateDirectories: true)
    }

    var testFolder: URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + name)
    }

    func wipeTestFolder() {
        try? FileManager.default.removeItem(at: testFolder)
    }

    func existingLocalURLIsExcludedFromBackup(_ folder: URL) throws -> Bool {
        let values = try folder.resourceValues(forKeys: [.isExcludedFromBackupKey])
        return values.isExcludedFromBackup == true
    }
}

/// This helper class is needed as the default file system will not report the value
/// of the `FileAttributeKey.protectionKey` when reading file attributes
final class FileManagerThatRecordsFileProtectionAttributes: FileManager {
    var recordedAttributes: [String: FileProtectionType] = [:]

    override func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        if let protectionType = attributes[FileAttributeKey.protectionKey] as? FileProtectionType {
            recordedAttributes[path] = protectionType
        }
        try super.setAttributes(attributes, ofItemAtPath: path)
    }

    func isFileProtectedUntilFirstUnlock(_ url: URL) -> Bool {
        recordedAttributes[url.path] == FileProtectionType.completeUntilFirstUserAuthentication
    }
}
