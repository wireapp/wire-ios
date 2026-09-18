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

// sourcery: AutoMockable
/// Holds a durable copy of each file being uploaded, since a background `URLSession` task needs a
/// file that stays readable out of process.
package protocol WireDriveDirectUploadFileCacheProtocol: Sendable {

    /// Copies the file at `sourceURL` into staging.
    func stage(sourceURL: URL, uploadID: UUID, fileName: String, isSecurityScoped: Bool) throws -> WireDriveStagedFile

    func stage(data: Data, uploadID: UUID, fileName: String) throws -> WireDriveStagedFile

    func url(stagedFileName: String) -> URL

    func exists(stagedFileName: String) -> Bool

    func delete(stagedFileName: String) throws

    /// Deletes staged files that no record refers to and that are older than `gracePeriod`.
    func sweepOrphans(referencedFileNames: Set<String>, gracePeriod: TimeInterval) throws
}

/// A file that has been copied into the upload staging directory.
package struct WireDriveStagedFile: Equatable, Hashable, Sendable {

    package let fileName: String

    package let url: URL

    package let size: UInt64

    package init(fileName: String, url: URL, size: UInt64) {
        self.fileName = fileName
        self.url = url
        self.size = size
    }
}
