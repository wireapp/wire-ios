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

package import Combine
package import Foundation

// sourcery: AutoMockable
@MainActor
package protocol WireDriveLocalAssetStoreProtocol: Sendable {

    /// Returns the `WireDriveLocalAsset` for a given `nodeID` or `nil`.
    func asset(nodeID: UUID) throws -> WireCellsLocalAsset?

    /// Updates an existing `WireDriveLocalAsset` or creates a new one if none exists with its `nodeID`.
    func upsertAsset(_ asset: WireDriveLocalAsset) throws

    /// Returns a publisher to monitor changes to an `WireDriveLocalAsset` for a given `nodeID`.
    func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never>

    /// Deletes all existing `WireCellsLocalAsset` for the given `nodeIDs`.
    func deleteAssets(nodeIDs: [UUID]) async throws

}
