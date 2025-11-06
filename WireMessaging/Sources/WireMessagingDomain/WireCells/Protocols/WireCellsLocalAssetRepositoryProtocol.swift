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
package import Combine

// sourcery: AutoMockable
/// Repository for accessing & updating `WireCellsLocalAsset`s.
package protocol WireCellsLocalAssetRepositoryProtocol: Sendable {

    /// Returns a `WireCellsLocalAsset` for the given `nodeID` or nil if metadata for the asset has has never been
    /// fetched.
    @MainActor
    func asset(nodeID: UUID) throws -> WireCellsLocalAsset?

    /// Refreshes the local asset metadata for a given `nodeID` and deletes any cached file if necessary.
    ///
    /// The metadata (name etc) and file associated with a given `nodeID` may change. This method fetches the latest
    /// metadata from the server, updates local metadata if it has changed and deletes any cached file if it's
    /// `eTag` has changed.
    @MainActor
    func refreshAssetMetadata(nodeID: UUID) async throws -> (node: WireCellsNode, asset: WireCellsLocalAsset)

    /// Downloads the asset for the given `nodeID`.
    ///
    /// This method first refreshes the assets metadata - see `refreshMetadata(nodeID:)`.
    /// The download can be observed via the `observeAsset(nodeID:)` method.
    @MainActor
    func downloadAsset(nodeID: UUID) async throws

    /// Observes the asset for the given `nodeID`. A value of `nil` is emitted if the asset has never been fetched.
    @MainActor
    func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never>

    /// Cancels the asset download for a given `nodeID`.
    @MainActor
    func cancelDownload(nodeID: UUID)

}
