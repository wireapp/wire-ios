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

import CoreData
import Foundation

/// A Wire Drive direct upload, persisted so that in-flight background transfers can be
/// reconciled after the app is suspended, terminated or force-quit by the user.
///
/// The bytes being uploaded are not stored here. They live in the upload staging directory and are
/// referenced by `stagedFileName`.

public final class WireDriveDirectUpload: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "WireDriveDirectUpload"

    /// The local identifier of the upload.
    ///
    /// This is the value carried in `URLSessionTask.taskDescription`, which is how a task is
    /// correlated back to its record after the app is relaunched.

    @NSManaged public var uploadID: UUID

    /// The identifier shared by every upload the user started in the same batch.
    ///
    /// A batch is one round of picking files, and is what the aggregate upload status is derived
    /// from (e.g. "5 of 8 uploaded").

    @NSManaged public var batchID: UUID

    /// The identifier the node will have on the Wire Drive backend once the upload is published.
    ///
    /// It is generated locally before the transfer starts, because it is part of the signed request.

    @NSManaged public var nodeID: UUID

    /// The identifier of the node version being created by this upload.

    @NSManaged public var versionID: UUID

    /// The remote key path of the folder the file is being uploaded into.
    ///
    /// Uploads are always scoped to the folder the user was browsing when they picked the file.

    @NSManaged public var destinationFolderPath: String

    /// The remote key path of the node itself, as resolved by the backend pre-check.
    ///
    /// This may differ from `destinationFolderPath` + `fileName` when the backend had to pick a
    /// different name to avoid a collision.

    @NSManaged public var nodePath: String

    /// The name the file will have on the backend.

    @NSManaged public var fileName: String

    /// The size of the file in bytes.

    @NSManaged public var fileSize: Int64

    /// The MIME type of the file, if known.

    @NSManaged public var mimeType: String?

    /// The name of the staged copy of the file within the upload staging directory.
    ///
    /// Only the name is stored, never a full URL, so that a change of container path (reinstall, OS
    /// update) cannot orphan the record.

    @NSManaged public var stagedFileName: String

    /// The raw value of the upload's lifecycle state.
    ///
    /// Mirrors `WireDriveUploadRecord.State` in `WireMessagingDomain`.

    @NSManaged public var state: Int16

    /// The date the upload was enqueued.

    @NSManaged public var createdAt: Date

    /// The date the upload's persisted state last changed.
    ///
    /// Upload progress deliberately does not update this: progress is never persisted.

    @NSManaged public var updatedAt: Date

    /// How many times this upload has been (re)started.
    ///
    /// Used to bound automatic restarts, e.g. after the presigned URL expires.

    @NSManaged public var attemptCount: Int16

    /// The identifier of the background `URLSession` carrying the transfer.

    @NSManaged public var sessionIdentifier: String?

    /// The `URLSessionTask.taskIdentifier` of the transfer, or `-1` if no task exists.
    ///
    /// Diagnostics only. Task identifiers are unique only within a session and are reused, so they
    /// are never used to correlate a task back to its record — `uploadID` is.

    @NSManaged public var taskIdentifier: Int64

    /// The presigned PUT URL the transfer uploads to.

    @NSManaged public var presignedURL: String?

    /// The date after which `presignedURL` is no longer accepted by the backend.

    @NSManaged public var presignedURLExpiresAt: Date?

    /// Additional signed headers the presigned request requires, as a JSON object.
    ///
    /// Normally `nil`: a presigned PUT carries its metadata in the query string, so the request
    /// needs no application headers. This exists so that a backend requiring extra signed headers
    /// can be supported without another model version.

    @NSManaged public var presignedRequestHeaders: String?

    /// The raw value of the reason the upload failed, or `0` if it has not failed.
    ///
    /// Mirrors `WireDriveUploadError` in `WireMessagingDomain`.

    @NSManaged public var failureReasonCode: Int16

    /// A human readable description of the failure, for logging only.
    ///
    /// Never surfaced to the user: it can contain raw backend error payloads.

    @NSManaged public var failureMessage: String?

}
