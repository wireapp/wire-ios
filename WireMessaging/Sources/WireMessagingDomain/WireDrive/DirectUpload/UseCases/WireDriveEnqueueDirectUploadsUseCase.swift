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

/// Accepts picked files for direct upload to Wire Drive.
///
/// The batch limit is enforced here rather than only in the picker: the picker's `selectionLimit` is
/// a convenience, this is the guarantee.
package struct WireDriveEnqueueDirectUploadsUseCase: WireDriveEnqueueDirectUploadsUseCaseProtocol {

    private let uploadManager: any WireDriveDirectUploadManagerProtocol

    package init(uploadManager: any WireDriveDirectUploadManagerProtocol) {
        self.uploadManager = uploadManager
    }

    @discardableResult
    package func invoke(
        sources: [WireDriveDirectUploadSource],
        destinationFolderPath: String
    ) async throws -> UUID {
        try await uploadManager.enqueue(
            sources: sources,
            destinationFolderPath: destinationFolderPath
        )
    }

    package func beginProcessingMedia(destinationFolderPath: String) async {
        await uploadManager.beginProcessingMedia(destinationFolderPath: destinationFolderPath)
    }

    package func endProcessingMedia(destinationFolderPath: String) async {
        await uploadManager.endProcessingMedia(destinationFolderPath: destinationFolderPath)
    }
}
