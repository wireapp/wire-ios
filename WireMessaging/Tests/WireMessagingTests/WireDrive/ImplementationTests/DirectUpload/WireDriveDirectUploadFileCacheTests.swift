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

import Foundation
import Testing

@testable import WireMessagingData
@testable import WireMessagingDomain

final class WireDriveDirectUploadFileCacheTests {

    private let directory: URL
    private let sut: WireDriveDirectUploadFileCache

    init() {
        self.directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("drive-upload-staging-tests-\(UUID().uuidString)", isDirectory: true)
        self.sut = WireDriveDirectUploadFileCache(directory: directory)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Staging

    @Test
    func stagesAFileFromDisk() async throws {
        // Given
        let uploadID = UUID()
        let source = try makeSourceFile(contents: "hello drive")

        // When
        let staged = try await sut.stage(
            sourceURL: source,
            uploadID: uploadID,
            fileName: "report.pdf",
            isSecurityScoped: false
        )

        // Then
        #expect(staged.fileName == "\(uploadID.uuidString)_report.pdf")
        #expect(staged.size == UInt64("hello drive".utf8.count))
        #expect(sut.exists(stagedFileName: staged.fileName))
        #expect(try String(contentsOf: staged.url, encoding: .utf8) == "hello drive")
    }

    /// The source may belong to Photos or a document provider, so it must be copied, never moved.
    @Test
    func leavesTheSourceFileInPlace() async throws {
        // Given
        let source = try makeSourceFile(contents: "hello")

        // When
        _ = try await sut.stage(sourceURL: source, uploadID: UUID(), fileName: "a.txt", isSecurityScoped: false)

        // Then
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    @Test
    func stagesRawData() async throws {
        // Given
        let uploadID = UUID()
        let data = Data("photo bytes".utf8)

        // When
        let staged = try await sut.stage(data: data, uploadID: uploadID, fileName: "photo.jpg")

        // Then
        #expect(staged.size == UInt64(data.count))
        #expect(try Data(contentsOf: staged.url) == data)
    }

    @Test
    func throwsWhenTheSourceIsMissing() async {
        // Given
        let missing = directory.appendingPathComponent("nope.txt")

        // Then
        await #expect(throws: WireDriveDirectUploadStagingError.sourceUnreadable(missing)) {
            try await sut.stage(sourceURL: missing, uploadID: UUID(), fileName: "nope.txt", isSecurityScoped: false)
        }
    }

    @Test
    func overwritesAPreviousStagingAttemptForTheSameUpload() async throws {
        // Given
        let uploadID = UUID()
        _ = try await sut.stage(data: Data("first".utf8), uploadID: uploadID, fileName: "a.txt")

        // When
        let staged = try await sut.stage(
            sourceURL: try makeSourceFile(contents: "second"),
            uploadID: uploadID,
            fileName: "a.txt",
            isSecurityScoped: false
        )

        // Then
        #expect(try String(contentsOf: staged.url, encoding: .utf8) == "second")
    }

    // MARK: - Naming

    /// Two files with the same name in one batch must not overwrite each other.
    @Test
    func namesStagedFilesUniquelyPerUpload() async throws {
        // When
        let first = await try sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "same.txt")
        let second = await try sut.stage(data: Data("b".utf8), uploadID: UUID(), fileName: "same.txt")

        // Then
        #expect(first.fileName != second.fileName)
    }

    @Test
    func replacesPathSeparatorsInFileNames() async throws {
        // When
        let staged = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "a/b\\c\"d.txt")

        // Then — a separator would otherwise be read as a subdirectory.
        #expect(!staged.fileName.contains("/"))
        #expect(!staged.fileName.contains("\\"))
        #expect(!staged.fileName.contains("\""))
    }

    @Test
    func truncatesOverlongFileNamesAndKeepsTheExtension() async throws {
        // Given
        let longName = String(repeating: "a", count: 400) + ".pdf"

        // When
        let staged = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: longName)

        // Then — must stay within the file system's 255 byte limit, prefix included.
        #expect(staged.fileName.utf8.count <= 255)
        #expect(staged.fileName.hasSuffix(".pdf"))
        #expect(sut.exists(stagedFileName: staged.fileName))
    }

    @Test
    func truncatesOverlongExtensionsWithinTheFileSystemLimit() async throws {
        // Given
        let longName = "report." + String(repeating: "x", count: 300)

        // When
        let staged = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: longName)

        // Then
        #expect(staged.fileName.utf8.count <= 255)
        #expect(sut.exists(stagedFileName: staged.fileName))
    }

    // MARK: - Protection

    /// `nsurlsessiond` reads the file out of process, possibly while the device is locked, so
    /// `.complete` would fail the transfer.
    ///
    /// The simulator does not enforce data protection and reports no protection attribute back, so
    /// this asserts on what the store *requests* rather than on what the file system stored. The
    /// effective level can only be confirmed on a device.
    @Test
    func requestsProtectionUntilFirstUserAuthenticationForStagedFiles() async throws {
        // Given
        let fileManager = SpyFileManager()
        let store = WireDriveDirectUploadFileCache(
            directory: directory.appendingPathComponent("protection", isDirectory: true),
            fileManager: fileManager
        )

        // When
        let staged = try await store.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "a.txt")

        // Then
        let requested = fileManager.requestedProtection[staged.url.path]
        #expect(requested == .completeUntilFirstUserAuthentication)
    }

    @Test
    func requestsProtectionUntilFirstUserAuthenticationForTheDirectory() async throws {
        // Given
        let fileManager = SpyFileManager()
        let stagingDirectory = directory.appendingPathComponent("protection-dir", isDirectory: true)
        let store = WireDriveDirectUploadFileCache(directory: stagingDirectory, fileManager: fileManager)

        // When
        _ = try await store.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "a.txt")

        // Then
        let requested = fileManager.requestedProtection[stagingDirectory.path]
        #expect(requested == .completeUntilFirstUserAuthentication)
    }

    // MARK: - Deletion

    @Test
    func deletesAStagedFile() async throws {
        // Given
        let staged = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "a.txt")

        // When
        try sut.delete(stagedFileName: staged.fileName)

        // Then
        #expect(!sut.exists(stagedFileName: staged.fileName))
    }

    @Test
    func deletingAMissingFileIsNotAnError() throws {
        try sut.delete(stagedFileName: "not-there.txt")
    }

    // MARK: - Orphan sweep

    @Test
    func sweepsUnreferencedFilesOlderThanTheGracePeriod() async throws {
        // Given
        let orphan = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "orphan.txt")
        let referenced = try await sut.stage(data: Data("b".utf8), uploadID: UUID(), fileName: "keep.txt")
        try backdate(orphan.url, by: -3600)
        try backdate(referenced.url, by: -3600)

        // When
        try sut.sweepOrphans(referencedFileNames: [referenced.fileName], gracePeriod: 60)

        // Then
        #expect(!sut.exists(stagedFileName: orphan.fileName))
        #expect(sut.exists(stagedFileName: referenced.fileName))
    }

    /// A file with no record may simply be mid-enqueue, since its record is written after the copy.
    /// The grace period is what stops the sweep racing that.
    @Test
    func doesNotSweepRecentlyStagedFiles() async throws {
        // Given
        let justStaged = try await sut.stage(data: Data("a".utf8), uploadID: UUID(), fileName: "new.txt")

        // When
        try sut.sweepOrphans(referencedFileNames: [], gracePeriod: 3600)

        // Then
        #expect(sut.exists(stagedFileName: justStaged.fileName))
    }

    @Test
    func sweepingAnAbsentDirectoryIsNotAnError() throws {
        // Given
        let store = WireDriveDirectUploadFileCache(
            directory: directory.appendingPathComponent("never-created", isDirectory: true)
        )

        // Then
        try store.sweepOrphans(referencedFileNames: [], gracePeriod: 0)
    }

    // MARK: - Helpers

    private func makeSourceFile(contents: String) throws -> URL {
        let sourceDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("drive-upload-source-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        let url = sourceDirectory.appendingPathComponent("source.bin")
        try Data(contents.utf8).write(to: url)
        return url
    }

    /// Records the protection level requested for each path, since the simulator does not report it
    /// back through `attributesOfItem(atPath:)`.
    private final class SpyFileManager: FileManager {

        private(set) var requestedProtection: [String: FileProtectionType] = [:]

        override func setAttributes(
            _ attributes: [FileAttributeKey: Any],
            ofItemAtPath path: String
        ) throws {
            if let protection = attributes[.protectionKey] as? FileProtectionType {
                requestedProtection[path] = protection
            }
            try super.setAttributes(attributes, ofItemAtPath: path)
        }
    }

    private func backdate(_ url: URL, by interval: TimeInterval) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: Date().addingTimeInterval(interval)],
            ofItemAtPath: url.path
        )
    }
}
