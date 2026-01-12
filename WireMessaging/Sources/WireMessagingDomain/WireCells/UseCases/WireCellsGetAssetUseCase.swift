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

/// Returns the URL to a locally cached file for a given node ID, and downloads it first if not already cached.
package struct WireCellsGetAssetUseCase {

    package enum Failure: Error {
        case invalidDownloadState
        case cachedFileMissing
    }

    private let localAssetRepository: any WireCellsLocalAssetRepositoryProtocol
    private let fileCache: any FileCache

    package init(
        localAssetRepository: any WireCellsLocalAssetRepositoryProtocol,
        fileCache: any FileCache
    ) {
        self.localAssetRepository = localAssetRepository
        self.fileCache = fileCache
    }

    package func invoke(nodeID: UUID) async throws -> URL {
        // If the file is already downloaded, return the local URL.
        if
            let cacheKey = try await localAssetRepository.asset(nodeID: nodeID)?.downloadState.cacheKey,
            let url = fileCache.fileURL(forKey: cacheKey) {
            return url
        }

        try await localAssetRepository.downloadAsset(nodeID: nodeID)
        guard let cacheKey = try await localAssetRepository.asset(nodeID: nodeID)?.downloadState.cacheKey else {
            throw Failure.invalidDownloadState
        }

        guard let fileURL = fileCache.fileURL(forKey: cacheKey) else {
            throw Failure.cachedFileMissing
        }

        return fileURL
    }

}
