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

/// The durable state of a Wire Drive direct upload — a value-type mirror of the
/// `WireDriveDirectUpload` Core Data entity.

package struct WireDriveDirectUploadRecord: Identifiable, Equatable, Hashable, Sendable {

    package enum State: Int16, Sendable, CaseIterable {

        /// The file has been copied into the staging directory. Nothing has been sent yet.

        case staged = 0

        /// The destination path has been resolved by the backend pre-check.

        case preChecked = 1

        /// A presigned URL has been minted, but no upload task exists yet.

        case awaitingStart = 2

        /// An upload task exists. It may or may not have started sending bytes.

        case uploading = 3

        /// The upload completed and the node is visible in the drive.

        case uploaded = 5

        case failed = 6

        case cancelled = 7

        /// Whether no further work will happen unless the user asks for it.

        package var isTerminal: Bool {
            switch self {
            case .uploaded, .failed, .cancelled: true
            case .staged, .preChecked, .awaitingStart, .uploading: false
            }
        }

        /// Whether the backend may already hold bytes for this upload.

        package var hasRemoteState: Bool {
            switch self {
            case .uploading, .uploaded: true
            case .staged, .preChecked, .awaitingStart, .failed, .cancelled: false
            }
        }
    }

    package var id: UUID { uploadID }

    package let uploadID: UUID
    package let batchID: UUID
    package let nodeID: UUID
    package let versionID: UUID

    package let destinationFolderPath: String

    package var nodePath: String

    package let fileName: String
    package let fileSize: UInt64
    package let mimeType: String?

    package let stagedFileName: String

    package var state: State

    package let createdAt: Date
    package var updatedAt: Date

    /// How many times the transfer has been started.

    package var attemptCount: Int

    package var sessionIdentifier: String?

    /// The `URLSessionTask.taskIdentifier`, or `nil` when no task exists.
    package var taskIdentifier: Int?

    package var presignedURL: URL?
    package var presignedURLExpiresAt: Date?
    package var presignedRequestHeaders: [String: String]

    package var failure: WireDriveUploadError?

    package init(
        uploadID: UUID,
        batchID: UUID,
        nodeID: UUID,
        versionID: UUID,
        destinationFolderPath: String,
        nodePath: String,
        fileName: String,
        fileSize: UInt64,
        mimeType: String? = nil,
        stagedFileName: String,
        state: State = .staged,
        createdAt: Date,
        updatedAt: Date,
        attemptCount: Int = 0,
        sessionIdentifier: String? = nil,
        taskIdentifier: Int? = nil,
        presignedURL: URL? = nil,
        presignedURLExpiresAt: Date? = nil,
        presignedRequestHeaders: [String: String] = [:],
        failure: WireDriveUploadError? = nil
    ) {
        self.uploadID = uploadID
        self.batchID = batchID
        self.nodeID = nodeID
        self.versionID = versionID
        self.destinationFolderPath = destinationFolderPath
        self.nodePath = nodePath
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.stagedFileName = stagedFileName
        self.state = state
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attemptCount = attemptCount
        self.sessionIdentifier = sessionIdentifier
        self.taskIdentifier = taskIdentifier
        self.presignedURL = presignedURL
        self.presignedURLExpiresAt = presignedURLExpiresAt
        self.presignedRequestHeaders = presignedRequestHeaders
        self.failure = failure
    }

    /// Whether the presigned URL is missing, expired, or too close to expiry to be worth using.
    package func needsPresignedURL(now: Date, margin: TimeInterval = 120) -> Bool {
        guard presignedURL != nil, let presignedURLExpiresAt else { return true }
        return presignedURLExpiresAt.timeIntervalSince(now) < margin
    }

    /// Whether two records differ only in fields that are not worth a database write.
    package func hasEqualPersistedFields(to other: WireDriveDirectUploadRecord) -> Bool {
        var lhs = self
        var rhs = other
        lhs.updatedAt = .distantPast
        rhs.updatedAt = .distantPast
        return lhs == rhs
    }
}

// MARK: - Presentation

package extension WireDriveDirectUploadRecord {

    /// The user-facing view of this record.
    func toItem(progress: Float?, isStagedFileAvailable: Bool) -> WireDriveDirectUploadItem {
        WireDriveDirectUploadItem(
            id: uploadID,
            batchID: batchID,
            nodeID: nodeID,
            fileName: fileName,
            fileSize: fileSize,
            destinationFolderPath: destinationFolderPath,
            status: itemStatus(progress: progress),
            createdAt: createdAt,
            isRetryable: isRetryable(isStagedFileAvailable: isStagedFileAvailable)
        )
    }

    private func itemStatus(progress: Float?) -> WireDriveDirectUploadItem.Status {
        switch state {
        case .staged, .preChecked, .awaitingStart:
            .queued

        case .uploading:
            // No bytes sent yet still reads as queued: a task can exist for a while before
            // `nsurlsessiond` gets round to starting it.
            if let progress, progress > 0 {
                .uploading(progress: progress)
            } else {
                .queued
            }

        case .uploaded:
            .uploaded

        case .failed:
            .failed(error: failure ?? .other(message: "unknown"))

        case .cancelled:
            .cancelled
        }
    }

    private func isRetryable(isStagedFileAvailable: Bool) -> Bool {
        guard state == .failed, isStagedFileAvailable else { return false }
        return failure?.isRetryable ?? true
    }
}
