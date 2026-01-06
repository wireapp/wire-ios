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

import CoreData
import Testing

@testable import WireData

@MainActor
struct WireCellsLocalAssetTests {

    private let container: NSPersistentContainer

    init() throws {
        self.container = try NSPersistentContainer.inMemoryContainer()
    }

    @Test
    func initialization() async throws {
        // given
        let context = container.viewContext
        let nodeID = UUID()

        let asset = WireCellsLocalAsset(context: context)
        asset.nodeID = nodeID
        asset.eTag = "etag"
        asset.path = "asset/path"
        asset.contentType = "image/png"
        asset.size = 1024
        asset.isDownloaded = true

        // when
        try context.save()

        // then
        let request = try #require(WireCellsLocalAsset.fetchRequest() as? NSFetchRequest<WireCellsLocalAsset>)
        let persisted = try #require(context.fetch(request).first)

        #expect(persisted.nodeID == nodeID)
        #expect(persisted.eTag == "etag")
        #expect(persisted.path == "asset/path")
        #expect(persisted.contentType == "image/png")
        #expect(persisted.size == 1024)
        #expect(persisted.isDownloaded == true)
    }

}

// MARK: - Helpers

private extension NSPersistentContainer {

    static func inMemoryContainer() throws -> NSPersistentContainer {
        let model = NSManagedObjectModel.mergedModel(from: [WireDataBundle.bundle])

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        let container = NSPersistentContainer(name: "zmessaging", managedObjectModel: model!)
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let loadError {
            throw loadError
        }
        return container
    }

}
