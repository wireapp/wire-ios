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

import Testing
import WireData
import WireDataModelSupport

@testable import WireDataModel

@MainActor
struct WireCellsLocalAssetTests {

    private let coreDataStack: CoreDataStack

    init() async throws {
        self.coreDataStack = try await CoreDataStackHelper().createStack()
    }

    @Test
    func initialization() async throws {
        // given
        let context = coreDataStack.viewContext
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
