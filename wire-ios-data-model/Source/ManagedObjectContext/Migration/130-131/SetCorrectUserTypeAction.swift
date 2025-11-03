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

import Foundation
import WireLegacyLogging

/// A new user-type property has been introduced with API v12.
/// Before users were either regular or service users.
/// Now users can be regular, apps or bots (former service) and a separate property will now store the type of users.

final class SetCorrectUserTypeAction: CoreDataMigrationAction {

    let batchSize = 200

    override func execute(in context: NSManagedObjectContext) {
        do {
            let fetchRequest = ZMUser.fetchRequest()
            fetchRequest.fetchBatchSize = batchSize
            let users = try context.fetch(fetchRequest) as! [ZMUser]
            for user in users {
                let type = if user.isServiceUser { TypeOfUser.bot } else { TypeOfUser.regular }
                user.setValue(type.rawValue, forKey: "typeValue")
            }
        } catch {
            WireLogger.localStorage.error(
                "Failed to set correct user type for users: \(error.localizedDescription)",
                attributes: .safePublic
            )
        }
    }
}
