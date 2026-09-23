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
package protocol WireDriveEnqueueDirectUploadsUseCaseProtocol: Sendable {

    /// Accepts picked files for upload into `destinationFolderPath`.
    @discardableResult
    func invoke(sources: [WireDriveDirectUploadSource], destinationFolderPath: String) async throws -> UUID

    /// Signals that one upload is currently being resolved for `destinationFolderPath`, before it
    /// exists as a record of its own.

    func beginProcessingMedia(destinationFolderPath: String) async

    /// Signals that resolving that one upload has finished, whether or not it produced anything to
    /// enqueue.

    func endProcessingMedia(destinationFolderPath: String) async

}
