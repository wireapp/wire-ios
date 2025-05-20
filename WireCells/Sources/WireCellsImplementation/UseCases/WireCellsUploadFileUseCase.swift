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

import Foundation
import WireCellsAPI
import WireLogging

package final class WireCellsUploadFileUseCase: WireCellsUploadFileUseCaseProtocol {

    private let cellName: String
    private let draftRepository: DraftsRepository

    package init(cellName: String, draftRepository: DraftsRepository) {
        self.cellName = cellName
        self.draftRepository = draftRepository
    }

    func invoke(fileURL: URL) async throws {
        guard let fileSize = try fileURL.resourceValues(forKeys: Set([.fileSizeKey])).fileSize else {
            throw WireCellsUploadFileUseCaseError.missingFileSize
        }

        await draftRepository.add(
            assetURL: fileURL,
            assetSize: UInt64(fileSize),
            cellName: cellName,
            fileName: fileURL.lastPathComponent
        )
    }

    func invoke(imageData: Data) async throws {
        // TODO: [WPB-17767] Implement
        WireLogger.wireCells.info("Uploading file from image data")
    }

}
