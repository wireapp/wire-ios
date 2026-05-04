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
package import UniformTypeIdentifiers

/// Represents a draft for a file upload in WireCells.
///
/// When a file is uploaded to wire drive, it is first stored as a draft. A draft is not visible in conversations and
/// is not searchable. When the user sends the file, the draft must be published so that it becomes visible in the
/// conversation etc.

public struct WireDriveDraft: Hashable, Sendable {

    /// Metadata for a draft

    public enum Metadata: Hashable, Sendable {

        /// Image metadata, containing width and height in pixels.

        case image(width: Int, height: Int)

        /// Video metadata, containing width and height in pixels, and duration in milliseconds.

        case video(width: Int, height: Int, duration: Int)

        /// Audio metadata, containing duration in milliseconds.

        case audio(duration: Int)

    }

    /// The ID of the node that represents the uploaded file.

    public let nodeID: UUID

    /// The ID of the version of the uploaded file. It is possible for the file for a particular node to be updated.
    /// `versionID` is necessary for some operations such as publishing a draft.

    package let versionID: UUID

    /// The URL of the asset that contains the file data.

    package let assetURL: URL

    /// The type of the file, represented as a Uniform Type Identifier (UTType). This value is determined locally.

    package let fileType: UTType?

    /// The status of the upload. This value can change over time as the upload progresses.

    public var status: WireDriveUploadStatus

    /// The name of the file. This value might be change if the desired name is already taken on the server.

    public var name: String

    /// The size of the file in bytes.

    public let bytes: Int

    /// The MIME type of the file, as determined by the server. This value is unknown until the file has been uploaded.

    public var mimeType: String?

    /// Whether the file should be deleted after it has been sent or cancelled etc.

    public let requiresCleanup: Bool

    /// Optional metadata for the draft, such as image dimensions or video duration. This allows recipients to display
    /// placeholders before a preview has been downloaded.

    public let metadata: Metadata?

    package init(
        nodeID: UUID,
        versionID: UUID,
        assetURL: URL,
        fileType: UTType?,
        status: WireDriveUploadStatus,
        name: String,
        bytes: Int,
        mimeType: String?,
        requiresCleanup: Bool,
        metadata: Metadata?
    ) {
        self.nodeID = nodeID
        self.versionID = versionID
        self.assetURL = assetURL
        self.fileType = fileType
        self.status = status
        self.name = name
        self.bytes = bytes
        self.mimeType = mimeType
        self.requiresCleanup = requiresCleanup
        self.metadata = metadata
    }
}
