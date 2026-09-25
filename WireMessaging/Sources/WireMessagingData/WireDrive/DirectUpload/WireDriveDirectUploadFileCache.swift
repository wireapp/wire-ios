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

package import Foundation
import WireLogging
package import WireMessagingDomain

package enum WireDriveDirectUploadStagingError: Error, Equatable {
    case sourceUnreadable(URL)
    case securityScopeDenied(URL)
    case copyFailed(String)
}

/// Holds a durable copy of each file being uploaded, in a directory shared with `nsurlsessiond`.
///
/// A copy is needed because a background upload task can only send a file (not a stream or a
/// temporary/security-scoped picker URL), and because a retry after a force-quit has nothing to
/// resend unless the bytes survived. Lives under Application Support, not Caches, since an evicted
/// file would turn a retryable upload into a permanent failure.

package final class WireDriveDirectUploadFileCache: WireDriveDirectUploadFileCacheProtocol {

    private enum Constants {
        static let maxFileNameBytes = 200
    }

    private let directory: URL
    private nonisolated(unsafe) let fileManager: FileManager

    package init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    // MARK: - Staging

    package func stage(
        sourceURL: URL,
        uploadID: UUID,
        fileName: String,
        isSecurityScoped: Bool
    ) async throws -> WireDriveStagedFile {
        try await Task.detached(priority: .utility) { [self] in
            try stageSynchronously(
                sourceURL: sourceURL,
                uploadID: uploadID,
                fileName: fileName,
                isSecurityScoped: isSecurityScoped
            )
        }.value
    }

    private func stageSynchronously(
        sourceURL: URL,
        uploadID: UUID,
        fileName: String,
        isSecurityScoped: Bool
    ) throws -> WireDriveStagedFile {
        try createDirectoryIfNeeded()

        let stagedFileName = makeStagedFileName(uploadID: uploadID, fileName: fileName)
        let destination = url(stagedFileName: stagedFileName)

        var didStartAccessing = false

        if isSecurityScoped {
            didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
            guard didStartAccessing else {
                throw WireDriveDirectUploadStagingError.securityScopeDenied(sourceURL)
            }
        }

        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw WireDriveDirectUploadStagingError.sourceUnreadable(sourceURL)
        }

        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
        } catch {
            throw WireDriveDirectUploadStagingError.copyFailed(error.localizedDescription)
        }

        try protectFile(at: destination)

        return WireDriveStagedFile(
            fileName: stagedFileName,
            url: destination,
            size: try size(of: destination)
        )
    }

    package func stage(data: Data, uploadID: UUID, fileName: String) async throws -> WireDriveStagedFile {
        try await Task.detached(priority: .utility) { [self] in
            try stageSynchronously(data: data, uploadID: uploadID, fileName: fileName)
        }.value
    }

    private func stageSynchronously(data: Data, uploadID: UUID, fileName: String) throws -> WireDriveStagedFile {
        try createDirectoryIfNeeded()

        let stagedFileName = makeStagedFileName(uploadID: uploadID, fileName: fileName)
        let destination = url(stagedFileName: stagedFileName)

        do {
            try data.write(to: destination, options: .atomic)
        } catch {
            throw WireDriveDirectUploadStagingError.copyFailed(error.localizedDescription)
        }

        try protectFile(at: destination)

        return WireDriveStagedFile(
            fileName: stagedFileName,
            url: destination,
            size: UInt64(data.count)
        )
    }

    // MARK: - Lookup

    package func url(stagedFileName: String) -> URL {
        directory.appendingPathComponent(stagedFileName)
    }

    package func exists(stagedFileName: String) -> Bool {
        fileManager.fileExists(atPath: url(stagedFileName: stagedFileName).path)
    }

    package func delete(stagedFileName: String) throws {
        let fileURL = url(stagedFileName: stagedFileName)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    package func sweepOrphans(referencedFileNames: Set<String>, gracePeriod: TimeInterval) throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let cutoff = Date().addingTimeInterval(-gracePeriod)

        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            guard !referencedFileNames.contains(fileName) else { continue }

            // A file with no record may simply be mid-enqueue: its record is written after the
            // copy. The grace period is what keeps the sweep from racing that.
            let modified = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate
            guard let modified, modified < cutoff else { continue }

            do {
                try fileManager.removeItem(at: fileURL)
                WireLogger.wireDrive.info("swept orphaned staged upload file")
            } catch {
                WireLogger.wireDrive.warn("failed to sweep orphaned staged upload file: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
        }

        try protectFile(at: directory)

        var directory = directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? directory.setResourceValues(resourceValues)
    }

    /// Applies the only protection level a background transfer can work with.
    private func protectFile(at url: URL) throws {
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    private func size(of url: URL) throws -> UInt64 {
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.uint64Value ?? 0
    }

    private func makeStagedFileName(uploadID: UUID, fileName: String) -> String {
        let sanitized = WireDriveNodeNameSanitizer.sanitize(fileName)
            .replacingOccurrences(of: ":", with: "_")
        return "\(uploadID.uuidString)_\(truncate(sanitized))"
    }

    private func truncate(_ fileName: String) -> String {
        guard fileName.utf8.count > Constants.maxFileNameBytes else { return fileName }

        let pathExtension = (fileName as NSString).pathExtension
        let base = (fileName as NSString).deletingPathExtension
        let suffix = pathExtension.isEmpty ? "" : ".\(pathExtension)"
        let allowance = Constants.maxFileNameBytes - suffix.utf8.count

        var truncated = ""
        for character in base {
            if truncated.utf8.count + String(character).utf8.count > allowance { break }
            truncated.append(character)
        }

        return truncated + suffix
    }
}
