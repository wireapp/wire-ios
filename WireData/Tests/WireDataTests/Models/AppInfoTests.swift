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
        let context = container.newBackgroundContext()
        try await context.perform {

            // given
            let appInfo = AppInfo(context: context)
            appInfo.appDescription = "desc"
            appInfo.category = "cat"

            // when
            try context.save()

            // then
            let request = try #require(AppInfo.fetchRequest() as? NSFetchRequest<AppInfo>)
            let persisted = try #require(context.fetch(request).first)

            #expect(persisted.description == "desc")
            #expect(persisted.category == "cat")

        }
    }

}
