//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

class PrefillEvenHashAction: CoreDataMigrationAction {

    private enum Keys: String {
        case eventHash
        case entityName = "StoredUpdateEvent"
    }

    override func execute(in context: NSManagedObjectContext) throws {
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: Keys.entityName.rawValue)
            let objects = try context.fetch(request)

            objects.forEach { object in
                let uniqueKey = Int64.random(in: 0...Int64.max)
                object.setValue(uniqueKey, forKey: Keys.eventHash.rawValue)
            }
        } catch {
            WireLogger.localStorage.error("error fetching data \(Keys.entityName.rawValue) during PrefillPrimaryKeyAction: \(error.localizedDescription)")
        }
    }
}
