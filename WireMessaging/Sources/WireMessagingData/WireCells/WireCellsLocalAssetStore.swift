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
import CoreData
package import Foundation
package import WireData
package import WireMessagingDomain

private typealias ManagedLocalAsset = WireData.WireCellsLocalAsset

@MainActor
package final class WireCellsLocalAssetStore: WireCellsLocalAssetStoreProtocol {

    private let updates = PassthroughSubject<(UUID, WireMessagingDomain.WireCellsLocalAsset?), Never>()
    private let contextProvider: any ManagedObjectContextProvider
    private var assets: [UUID: WireMessagingDomain.WireCellsLocalAsset] = [:]

    package init(contextProvider: any ManagedObjectContextProvider) {
        self.contextProvider = contextProvider
    }

    package func asset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        if let asset = assets[nodeID] {
            return asset
        } else if let asset = try storedAsset(nodeID: nodeID) {
            assets[nodeID] = asset
            return asset
        } else {
            return nil
        }
    }

    package func upsertAsset(_ asset: WireMessagingDomain.WireCellsLocalAsset) throws {
        guard assets[asset.nodeID] != asset else { return }

        let oldAsset = assets[asset.nodeID]
        assets[asset.nodeID] = asset
        updates.send((asset.nodeID, asset))

        if let oldAsset, asset.hasEqualMetadata(to: oldAsset) { return }

        let context = contextProvider.newBackgroundContext()
        Task.detached {
            try await context.perform {
                let stored = try context.fetchLocalAsset(nodeID: asset.nodeID) ?? ManagedLocalAsset(context: context)
                stored.nodeID = asset.nodeID
                stored.eTag = asset.eTag
                stored.path = asset.path
                stored.contentType = asset.contentType
                stored.size = asset.size.map { Int64($0) } ?? -1
                stored.isDownloaded = asset.isDownloaded

                try context.save()
            }
        }
    }

    package func observeAsset(nodeID: UUID) -> AnyPublisher<WireMessagingDomain.WireCellsLocalAsset?, Never> {
        updates
            .filter { $0.0 == nodeID }
            .map(\.1)
            .prepend([try? asset(nodeID: nodeID)])
            .eraseToAnyPublisher()
    }

    package func deleteAssets(nodeIDs: [UUID]) async throws {
        for nodeID in nodeIDs {
            assets[nodeID] = nil
            updates.send((nodeID, nil))
        }

        let context = contextProvider.newBackgroundContext()
        try await Task.detached {
            try await context.perform {
                for nodeID in nodeIDs {
                    if let stored = try context.fetchLocalAsset(nodeID: nodeID) {
                        context.delete(stored)
                    }
                }
                try context.save()
            }
        }.value
    }

    // MARK: Helpers

    private func storedAsset(nodeID: UUID) throws -> WireMessagingDomain.WireCellsLocalAsset? {
        let context = contextProvider.viewContext
        return try context.performAndWait {
            try context.fetchLocalAsset(nodeID: nodeID).map { managed in
                let cacheKey = WireCellsLocalAsset.cacheKey(
                    nodeID: managed.nodeID,
                    eTag: managed.eTag,
                    path: managed.path
                )
                return WireCellsLocalAsset(
                    nodeID: managed.nodeID,
                    eTag: managed.eTag,
                    path: managed.path,
                    contentType: managed.contentType,
                    size: managed.size >= 0 ? UInt64(managed.size) : nil,
                    downloadState: managed.isDownloaded ? .downloaded(cacheKey: cacheKey) : .pending
                )
            }
        }
    }

}

// MARK: Private helpers

private extension WireMessagingDomain.WireCellsLocalAsset {

    var isDownloaded: Bool {
        switch downloadState {
        case .downloaded:
            true
        default:
            false
        }
    }

    func hasEqualMetadata(to other: WireMessagingDomain.WireCellsLocalAsset) -> Bool {
        eTag == other.eTag
            && path == other.path
            && contentType == other.contentType
            && size == other.size
            && isDownloaded == other.isDownloaded
    }

}

private extension NSManagedObjectContext {

    func fetchLocalAsset(nodeID: UUID) throws -> ManagedLocalAsset? {
        let request = ManagedLocalAsset.fetchRequest() as! NSFetchRequest<ManagedLocalAsset>
        request.predicate = NSPredicate(format: "nodeID == %@", nodeID as any CVarArg)
        request.fetchLimit = 1
        return try fetch(request).first
    }

}
