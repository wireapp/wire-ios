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

package enum WireDriveEmptyRecycleBinError: Error {
    case serverFailedToEmptyRecycleBin
}

/// Permanently deletes the contents of a cell's recycle bin.
package struct WireDriveEmptyRecycleBinUseCase {

    private let repository: any WireDriveNodesRepositoryProtocol
    private let fileCache: any FileCache
    private let localAssetStore: any WireDriveLocalAssetStoreProtocol

    package init(
        repository: any WireDriveNodesRepositoryProtocol,
        fileCache: any FileCache,
        localAssetStore: any WireDriveLocalAssetStoreProtocol
    ) {
        self.repository = repository
        self.fileCache = fileCache
        self.localAssetStore = localAssetStore
    }

    package func invoke(cellName: String) async throws {
        let recycleBinPath = "\(cellName)/recycle_bin"
        guard try await repository.deleteNodes(locators: [.path(recycleBinPath)], permanently: true) else {
            throw WireDriveEmptyRecycleBinError.serverFailedToEmptyRecycleBin
        }
    }
}
