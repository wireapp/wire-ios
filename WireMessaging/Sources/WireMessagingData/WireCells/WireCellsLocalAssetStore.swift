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

package import Combine
package import Foundation
package import WireMessagingDomain

@MainActor
package final class WireCellsLocalAssetStore {

    private let updates = PassthroughSubject<(UUID, WireCellsLocalAsset?), Never>()
    private var assets: [UUID: WireCellsLocalAsset] = [:]

    package init() {}

    func asset(nodeID: UUID) throws -> WireCellsLocalAsset? {
        assets[nodeID]

        // TODO: lazy populate from persistent store
    }

    func upsertAsset(_ asset: WireCellsLocalAsset) throws {
        guard assets[asset.nodeID] != asset else { return }

        assets[asset.nodeID] = asset
        updates.send((asset.nodeID, asset))

        // TODO: Update persistent store if necessary)
    }

    func deleteAsset(nodeID: UUID) throws {
        guard assets.removeValue(forKey: nodeID) != nil else { return }

        updates.send((nodeID, nil))

        // TODO: Update persistent store if necessary)
    }

    @MainActor
    package func observeAsset(nodeID: UUID) -> AnyPublisher<WireCellsLocalAsset?, Never> {
        updates
            .filter { $0.0 == nodeID }
            .map(\.1)
            .prepend([try? asset(nodeID: nodeID)])
            .eraseToAnyPublisher()
    }

}
