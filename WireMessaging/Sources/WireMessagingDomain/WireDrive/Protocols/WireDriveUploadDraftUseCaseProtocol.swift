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

/// Uploads file as a draft to the drive server.

public protocol WireDriveUploadDraftUseCaseProtocol: Sendable {

    /// Uploads the file at `fileURL` to the drive server.

    func invoke(fileURL: URL) async throws

    /// Creates a file using `imageData` and uploads it to the drive server.

    func invoke(data: Data, type: UTType) async throws

    var charactersToReplace: [Character] { get }
}

public enum WireDriveUploadDraftUseCaseError: Error, Sendable {

    /// The file size of the requested file cannot be determined.

    case missingFileSize

}
