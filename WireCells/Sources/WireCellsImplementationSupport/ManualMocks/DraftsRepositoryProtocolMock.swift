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
package import UniformTypeIdentifiers
package import WireCellsAPI
import WireCellsImplementation

package actor DraftsRepositoryProtocolMock: DraftsRepositoryProtocol {

    // MARK: - add

    package var addAssetURLURLAssetSizeIntCellNameStringFileNameStringFileTypeUTTypeVoidReceivedArguments:
        (assetURL: URL, assetSize: Int, cellName: String, fileName: String, fileType: UTType?)?

    package func add(assetURL: URL, assetSize: Int, cellName: String, fileName: String, fileType: UTType?) async {
        addAssetURLURLAssetSizeIntCellNameStringFileNameStringFileTypeUTTypeVoidReceivedArguments =
            (assetURL, assetSize, cellName, fileName, fileType)
    }

    // MARK: - drafts

    private(set) var draftsForCellNameStringAsyncStreamWireCellsDraftReceivedCellName: String?
    package var draftsForCellNameStringAsyncStreamWireCellsDraftReturnValue: AsyncStream<[WireCellsDraft]>!

    package func drafts(for cellName: String) -> AsyncStream<[WireCellsDraft]> {
        draftsForCellNameStringAsyncStreamWireCellsDraftReceivedCellName = cellName
        return draftsForCellNameStringAsyncStreamWireCellsDraftReturnValue
    }

    package func setDraftsForCellNameStringAsyncStreamWireCellsDraftReturnValue(
        _ value: AsyncStream<[WireCellsDraft]>
    ) {
        draftsForCellNameStringAsyncStreamWireCellsDraftReturnValue = value
    }

    func publishAll(for cellName: String) async throws {}

}
