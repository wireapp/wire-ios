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

import WireDataModel
import WireDomain
import WireLogging

/// Version 4.18 is the first which supports API v15 and can deal with the user's `type` value (`.regular`, `.app`, `.bot`).
/// This migration triggers a sync of all users in order to fetch the correct `type`.
struct AppVersionMigration_4_18_0: AppVersionMigration {

    let version: SemanticVersion = "4.17.0" // TODO: change to 4.18.0
    let coreDataStack: CoreDataStackProtocol

    func perform() async throws {

        let context = coreDataStack.syncContext
        try await context.perform { [context] in
            let fetchRequest = ZMUser.fetchRequest()
            fetchRequest.propertiesToFetch = ["needsToBeUpdatedFromBackend"]
            let users = try context.fetch(fetchRequest) as! [ZMUser]
            users.forEach { user in
                user.needsToBeUpdatedFromBackend = true
            }
            try context.save()
        }

    }
}
