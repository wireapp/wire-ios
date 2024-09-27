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
@testable import WireUtilities

// MARK: - FileManagerMoveTests

class FileManagerMoveTests: XCTestCase {
    override func setUp() {
        super.setUp()
        wipeDirectories()
        try! FileManager.default.createDirectory(at: tempFolder1, withIntermediateDirectories: true)
    }

    override func tearDown() {
        super.tearDown()
        wipeDirectories()
    }

    func testThatItMovesOneFolder() throws {
        // GIVEN
        let files = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah",
        ]
        createFiles(in: tempFolder1, relativeFilePaths: files)

        // WHEN
        try FileManager.default.moveFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        for file in files {
            checkIfFileExists(in: tempFolder2, relativePath: file)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder1.path))
    }

    func testThatItMovesOneFolderOverAnExistingOne() throws {
        // GIVEN
        let filesToMove = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah",
        ]
        let preExistingFiles = [
            "foo/bar/extra.file",
            "meh.bah",
        ]
        createFiles(in: tempFolder1, relativeFilePaths: filesToMove)
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles)

        // WHEN
        try FileManager.default.moveFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        for item in filesToMove + preExistingFiles {
            checkIfFileExists(in: tempFolder2, relativePath: item)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempFolder1.path))
    }

    func testThatItDoesNotOverwriteFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile,
        ]

        createFiles(in: tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")

        // WHEN
        try FileManager.default.moveFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: false
        )

        // THEN
        checkIfFileExists(in: tempFolder2, relativePath: overwrittenExistingFile, content: "DESTINATION")
        checkIfFileExists(in: tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }

    func testThatItOverwritesFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile,
        ]

        createFiles(in: tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")

        // WHEN
        try FileManager.default.moveFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        checkIfFileExists(in: tempFolder2, relativePath: overwrittenExistingFile, content: "SOURCE")
        checkIfFileExists(in: tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
}

// MARK: Copy

extension FileManagerMoveTests {
    func testThatItCopiesOneFolder() throws {
        // GIVEN
        let files = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah",
        ]
        createFiles(in: tempFolder1, relativeFilePaths: files)

        // WHEN
        try FileManager.default.copyFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        for file in files {
            checkIfFileExists(in: tempFolder2, relativePath: file)
            checkIfFileExists(in: tempFolder1, relativePath: file)
        }
    }

    func testThatItCopiesOneFolderOverAnExistingOne() throws {
        // GIVEN
        let filesToMove = [
            "foo/bar/x.dat",
            "bam/bar/dat.txt",
            "baz.md",
            "foo/eh.ah",
        ]
        let preExistingFiles = [
            "foo/bar/extra.file",
            "meh.bah",
        ]
        createFiles(in: tempFolder1, relativeFilePaths: filesToMove)
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles)

        // WHEN
        try FileManager.default.copyFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        for item in filesToMove + preExistingFiles {
            checkIfFileExists(in: tempFolder2, relativePath: item)
        }
    }

    func testThatItDoesNotCopyOverwriteFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile,
        ]

        createFiles(in: tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")

        // WHEN
        try FileManager.default.copyFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: false
        )

        // THEN
        checkIfFileExists(in: tempFolder2, relativePath: overwrittenExistingFile, content: "DESTINATION")
        checkIfFileExists(in: tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }

    func testThatItCopyOverwritesFilesInTheDestinationDirectory() throws {
        // GIVEN
        let nonOverwrittenExistingFile = "foo/eh.ah"
        let overwrittenExistingFile = "meh.bah"
        let preExistingFiles = [overwrittenExistingFile, nonOverwrittenExistingFile]
        let filesToMove = [
            "baz.md",
            overwrittenExistingFile,
        ]

        createFiles(in: tempFolder1, relativeFilePaths: filesToMove, content: "SOURCE")
        createFiles(in: tempFolder2, relativeFilePaths: preExistingFiles, content: "DESTINATION")

        // WHEN
        try FileManager.default.copyFolderRecursively(
            from: tempFolder1,
            to: tempFolder2,
            overwriteExistingFiles: true
        )

        // THEN
        checkIfFileExists(in: tempFolder2, relativePath: overwrittenExistingFile, content: "SOURCE")
        checkIfFileExists(in: tempFolder2, relativePath: nonOverwrittenExistingFile, content: "DESTINATION")
    }
}

extension FileManagerMoveTests {
    var tempFolder1: URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + "/FimeManagerMoveTests/1")
    }

    var tempFolder2: URL {
        URL(fileURLWithPath: NSTemporaryDirectory() + "/FimeManagerMoveTests/2")
    }

    func wipeDirectories() {
        try? FileManager.default.removeItem(at: tempFolder1)
        try? FileManager.default.removeItem(at: tempFolder2)
    }

    /// Create dummy files
    /// - parameter in: root folder where to create the file
    /// - parameter relativeFilePaths: path of the files to create, relative to the root folder
    func createFiles(in folder: URL, relativeFilePaths: [String], content: String? = nil) {
        for filePath in relativeFilePaths {
            let fullURL = folder.appendingPathComponent(filePath)
            let directory = fullURL.deletingLastPathComponent()
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = (content ?? filePath).data(using: .utf8)
            try! data?.write(to: fullURL)
        }
    }

    func checkIfFileExists(in folder: URL, relativePath: String, content: String? = nil) {
        let fileURL = folder.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fileURL) else {
            XCTFail("File \(relativePath) not readable")
            return
        }
        let fileContent = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(fileContent, content ?? relativePath)
    }
}
