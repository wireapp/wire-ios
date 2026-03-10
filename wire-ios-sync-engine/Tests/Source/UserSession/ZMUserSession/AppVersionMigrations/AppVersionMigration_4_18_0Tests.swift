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

import Testing
import WireDataModelSupport

@testable import WireSyncEngine

struct AppVersionMigration_4_18_0Tests {

    let coreDataHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    let stack: CoreDataStack
    let sut: AppVersionMigration_4_18_0

    init() async throws {
        self.stack = try await coreDataHelper.createStack()
        self.sut = AppVersionMigration_4_18_0(
            coreDataStack: stack
        )
    }

    func `test needsToBeUpdatedFromBackend is set to true`() async throws {

        // GIVEN
        let context = stack.syncContext
        let needsUpdateBefore = try await context.perform {
            modelHelper.createUser(in: context)
            modelHelper.createUser(in: context)
            try context.save()

            let fetchRequest = ZMUser.fetchRequest()
            fetchRequest.propertiesToFetch = ["needsToBeUpdatedFromBackend"]
            let users = try context.fetch(fetchRequest) as! [ZMUser]
            return users.map(\.needsToBeUpdatedFromBackend)
        }
        #expect(needsUpdateBefore == [false, false])

        // WHEN
        try await sut.perform()

        // THEN
        let needsUpdateAfter = try await context.perform {
            let fetchRequest = ZMUser.fetchRequest()
            fetchRequest.propertiesToFetch = ["needsToBeUpdatedFromBackend"]
            let users = try context.fetch(fetchRequest) as! [ZMUser]
            return users.map(\.needsToBeUpdatedFromBackend)
        }
        #expect(needsUpdateAfter == [true, true])

    }

}
