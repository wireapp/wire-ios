//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

package enum WireCellsAWSClientError: Error {
    case downloadError
    case downloadErrorNoData
    case downloadErrorUnknownObject
    case missingUploadID
    case noContent
    case uploadError
    case writeError
}

package protocol WireCellsAWSClient: Sendable {
    /// Downloads an object from S3 to a given writable OutputStream.
    func download(
        objectKey: String,
        to fileHandle: FileHandle,
        onProgressUpdate: @escaping @Sendable (UInt64) -> Void
    ) async throws

    /// Uploads a file at a local path to S3, using metadata from the CellNode.
    func upload(
        path: URL,
        node: WireCellsNodeDTO
    ) async -> AsyncThrowingStream<Int, any Error>

    /// Returns a pre-signed URL for the given S3 object key.
    func getPreSignedUrl(objectKey: String) async throws -> String
}
