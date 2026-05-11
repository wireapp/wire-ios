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
package struct WireDriveRemoveAssetAvailableOfflineUseCase {

    enum Failure: Error {
        case assetNotFound
    }

    private let localAssetRepository: any WireDriveLocalAssetRepositoryProtocol

    package init(localAssetRepository: any WireDriveLocalAssetRepositoryProtocol) {
        self.localAssetRepository = localAssetRepository
    }

    package func invoke(nodeID: UUID) async throws {
        guard var asset = try localAssetRepository.asset(nodeID: nodeID) else {
            throw Failure.assetNotFound
        }

        asset.isAvailableOffline = false

        // This is a temporary solution to automatically clean up some storage space
        // on the user's device. Later we want to implement a proper Storage Manager
        // where users will be able to clean up by deleting files manually and with
        // more control. Then we will no longer need this automatic deletion anymore.
        try await localAssetRepository.deleteAsset(nodeID: nodeID)

        try await localAssetRepository.updateAssetAsync(asset)
    }
}
