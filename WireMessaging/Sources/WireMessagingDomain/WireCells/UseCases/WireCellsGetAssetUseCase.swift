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

/// Returns the URL to a locally cached file for a given node ID, and downloads it first if not already cached.
@MainActor
package class WireCellsGetAssetUseCase {

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

    package func invoke(source: AssetSource) async throws -> URL {
        // If the file is already downloaded, return the local URL.
        if
            let cacheKey = try localAssetRepository.asset(nodeID: source.id)?.downloadState.cacheKey,
            let url = fileCache.fileURL(forKey: cacheKey) {
            return url
        }

        let cacheKey: String?

        do {
            try await localAssetRepository.downloadAsset(source: source)
            cacheKey = try localAssetRepository.asset(nodeID: source.id)?.downloadState.cacheKey
        } catch WireCellsLocalAssetRepositoryError.downloadAlreadyInProgress {
            try await awaitDownload(id: source.id)
            cacheKey = try localAssetRepository.asset(nodeID: source.id)?.downloadState.cacheKey
        }

        guard let cacheKey else {
            throw Failure.invalidDownloadState
        }

        guard let fileURL = fileCache.fileURL(forKey: cacheKey) else {
            throw Failure.cachedFileMissing
        }

        return fileURL
    }

    private func awaitDownload(id: UUID) async throws {
        for await item in localAssetRepository.observeAsset(nodeID: id).values {
            try Task.checkCancellation()

            switch item?.downloadState {
            case .downloaded:
                return
            case let .failed(error):
                throw error
            default:
                break
            }
        }
    }

}
