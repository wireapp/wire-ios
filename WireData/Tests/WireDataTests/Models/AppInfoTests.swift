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
struct AppInfoTests {

    private let container = try! NSPersistentContainer.inMemoryContainer()

    @Test
    func initialization() async throws {
        // given
        let context = container.newBackgroundContext()
        await context.perform {
            let appInfo = AppInfo(context: context)
            appInfo.appDescription = "desc"
            appInfo.category = "cat"
        }

        fatalError("TODO: Implement test")
        /*

        // when
        await context.perform {
            try context.save()
        }

        // withExtendedLifetime(<#T##x: ~Copyable & ~Escapable##~Copyable & ~Escapable#>, <#T##body: () throws(Error) -> ~Copyable##() throws(Error) -> ~Copyable#>)

        // then
        let request = try #require(WireCellsLocalAsset.fetchRequest() as? NSFetchRequest<WireCellsLocalAsset>)
        let persisted = try #require(context.fetch(request).first)

        #expect(persisted.nodeID == nodeID)
        #expect(persisted.eTag == "etag")
        #expect(persisted.path == "asset/path")
        #expect(persisted.contentType == "image/png")
        #expect(persisted.size == 1024)
        #expect(persisted.isDownloaded == true)
         */
    }

}
