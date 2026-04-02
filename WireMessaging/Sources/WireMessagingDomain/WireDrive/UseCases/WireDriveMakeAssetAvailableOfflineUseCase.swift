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

@MainActor
package struct WireDriveMakeAssetAvailableOfflineUseCase {

    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol

    package init(localAssetRepository: any WireDriveLocalAssetRepositoryProtocol) {
        self.localAssetRepository = localAssetRepository
    }

    package func invoke(nodeID: UUID) async throws {
        if var asset = try localAssetRepository.asset(nodeID: nodeID), asset.downloadState.cacheKey != nil {
            asset.isAvailableOffline = true
            try localAssetRepository.updateAsset(asset)
        } else {
            try await localAssetRepository.downloadAsset(nodeID: nodeID, isAvailableOffline: true)
        }
    }
}
