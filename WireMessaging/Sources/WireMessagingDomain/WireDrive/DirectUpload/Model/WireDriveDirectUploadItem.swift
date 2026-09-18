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

public import Foundation

/// A single Wire Drive direct upload, as observed by the UI.

public struct WireDriveDirectUploadItem: Identifiable, Equatable, Hashable, Sendable {

    /// The status of an upload, as shown to the user.

    public enum Status: Equatable, Hashable, Sendable {

        case queued
        case uploading(progress: Float)
        case uploaded
        case failed(error: WireDriveUploadError)
        case cancelled

        public var isQueued: Bool {
            self == .queued
        }

        public var isUploading: Bool {
            switch self {
            case .uploading: true
            default: false
            }
        }

        public var isUploaded: Bool {
            self == .uploaded
        }

        public var isFailed: Bool {
            switch self {
            case .failed: true
            default: false
            }
        }

        public var isCancelled: Bool {
            self == .cancelled
        }

        public var progress: Float {
            switch self {
            case .queued: 0
            case let .uploading(progress): progress
            case .uploaded: 1
            case .failed, .cancelled: 0
            }
        }

        public var error: WireDriveUploadError? {
            switch self {
            case let .failed(error): error
            default: nil
            }
        }
    }

    /// The local identifier of the upload.

    public let id: UUID

    /// The identifier shared by every upload started in the same round of picking files.

    public let batchID: UUID

    /// The identifier the node has, or will have, on the backend.

    public let nodeID: UUID

    public let fileName: String

    /// The size of the file in bytes.

    public let fileSize: UInt64

    /// The remote key path of the folder the file is being uploaded into.

    public let destinationFolderPath: String

    public let status: Status

    public let createdAt: Date

    /// Whether the mechanism can still be asked to retry this upload.

    public let isRetryable: Bool

    /// How many bytes have been sent so far.
    
    public var bytesSent: UInt64 {
        UInt64((Float(fileSize) * status.progress).rounded())
    }

    public init(
        id: UUID,
        batchID: UUID,
        nodeID: UUID,
        fileName: String,
        fileSize: UInt64,
        destinationFolderPath: String,
        status: Status,
        createdAt: Date,
        isRetryable: Bool
    ) {
        self.id = id
        self.batchID = batchID
        self.nodeID = nodeID
        self.fileName = fileName
        self.fileSize = fileSize
        self.destinationFolderPath = destinationFolderPath
        self.status = status
        self.createdAt = createdAt
        self.isRetryable = isRetryable
    }
}

/// The state of every tracked Wire Drive direct upload at a point in time

public struct WireDriveDirectUploadsSummary: Equatable, Sendable {

    public let items: [WireDriveDirectUploadItem]
    public let queuedCount: Int
    public let uploadingCount: Int
    public let uploadedCount: Int
    public let failedCount: Int
    public let cancelledCount: Int
    public let overallProgress: Float

    public static let empty = WireDriveDirectUploadsSummary(items: [])

    public var activeCount: Int {
        queuedCount + uploadingCount
    }

    public var trackedCount: Int {
        items.count - cancelledCount
    }

    public var isFinished: Bool {
        activeCount == 0
    }

    public var hasFailures: Bool {
        failedCount > 0
    }

    public var hasRetryableFailures: Bool {
        items.contains { $0.status.isFailed && $0.isRetryable }
    }

    public init(items: [WireDriveDirectUploadItem]) {
        let sorted = items.sorted { $0.createdAt < $1.createdAt }
        self.items = sorted

        var queued = 0
        var uploading = 0
        var uploaded = 0
        var failed = 0
        var cancelled = 0
        var totalBytes: UInt64 = 0
        var sentBytes: UInt64 = 0

        for item in sorted {
            switch item.status {
            case .queued: queued += 1
            case .uploading: uploading += 1
            case .uploaded: uploaded += 1
            case .failed: failed += 1
            case .cancelled: cancelled += 1
            }

            guard !item.status.isCancelled else { continue }

            totalBytes += item.fileSize
            sentBytes += item.bytesSent
        }

        self.queuedCount = queued
        self.uploadingCount = uploading
        self.uploadedCount = uploaded
        self.failedCount = failed
        self.cancelledCount = cancelled
        self.overallProgress = totalBytes > 0 ? Float(sentBytes) / Float(totalBytes) : 0
    }
}
