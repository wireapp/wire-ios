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

class PrefillPrimaryKeyAction: CoreDataMigrationAction {
    // MARK: Internal

    let batchSize = 200
    let entityNames = [ZMUser.entityName(), ZMConversation.entityName()]

    override func execute(in context: NSManagedObjectContext) throws {
        for entityName in entityNames {
            fillPrimaryKeys(for: entityName, context: context)
        }
    }

    // MARK: Private

    private enum Keys: String {
        case primaryKey
    }

    private func fillPrimaryKeys(for entityName: String, context: NSManagedObjectContext) {
        do {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.fetchBatchSize = batchSize
            let objects = try context.fetch(request)

            for object in objects {
                let uniqueKey = PrimaryKeyGenerator.generateKey(for: object, entityName: entityName)
                object.setValue(uniqueKey, forKey: Keys.primaryKey.rawValue)
            }
        } catch {
            WireLogger.localStorage
                .error(
                    "error fetching data \(entityName) during PrefillPrimaryKeyAction: \(error.localizedDescription)"
                )
        }
    }
}
