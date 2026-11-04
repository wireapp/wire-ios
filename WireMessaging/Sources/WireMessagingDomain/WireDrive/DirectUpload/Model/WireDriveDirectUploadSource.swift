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
public import UniformTypeIdentifiers

/// A file the user picked for a direct upload, before it has been staged.
public struct WireDriveDirectUploadSource: Equatable, Hashable, Sendable {

    /// Where the bytes currently are.

    public let url: URL

    /// The name the file should have in the drive.

    public let fileName: String

    /// The type of the file, if the picker reported one.

    public let fileType: UTType?

    /// Whether `url` must be accessed inside `startAccessingSecurityScopedResource()`.
    ///
    /// `true` for the document picker, `false` for files the photo picker has already exported.

    public let isSecurityScoped: Bool

    /// The Photos identifier of the asset, when the file came from the photo library.

    public let localIdentifier: String?

    public init(
        url: URL,
        fileName: String,
        fileType: UTType? = nil,
        isSecurityScoped: Bool = false,
        localIdentifier: String? = nil
    ) {
        self.url = url
        self.fileName = fileName
        self.fileType = fileType
        self.isSecurityScoped = isSecurityScoped
        self.localIdentifier = localIdentifier
    }
}

/// Limits applied to Wire Drive direct uploads.

public enum WireDriveDirectUploadLimits {

    /// How many files the user may pick in one go.
    public static let maxFilesPerBatch = 20
}

/// A reason a batch of direct uploads could not be enqueued at all.
public enum WireDriveDirectUploadBatchError: Error, Equatable, Hashable, Sendable {

    /// More files were picked than `WireDriveDirectUploadLimits.maxFilesPerBatch` allows.

    case tooManyFiles(limit: Int)

    /// The batch contained no files.

    case noFiles

    /// A picked file could not be copied into the staging directory.

    case stagingFailed(fileName: String, message: String)
}
