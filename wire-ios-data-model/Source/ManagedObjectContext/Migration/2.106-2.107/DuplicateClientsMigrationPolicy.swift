//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireSystem

class DuplicateClientsMigrationPolicy: NSEntityMigrationPolicy {

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
    }

    private let zmLog = ZMSLog(tag: "core-data")

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        zmLog.safePublic("beginning duplicate clients migration", level: .info)
        WireLogger.localStorage.info("beginning duplicate clients migration")

        let context = manager.sourceContext

        let duplicates: [String: [NSManagedObject]] = context.findDuplicated(
            entityName: UserClient.entityName(),
            by: #keyPath(UserClient.remoteIdentifier)
        )

        zmLog.safePublic(SanitizedString(stringLiteral: "found (\(duplicates.count)) occurences of duplicate clients"), level: .info)
        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate clients")

        duplicates.forEach { (_, clients: [NSManagedObject]) in
            guard clients.count > 1 else {
                return
            }

            clients.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            clients.dropFirst().forEach(context.delete)
            zmLog.safePublic("removed 1 occurence of duplicate clients", level: .warn)
            WireLogger.localStorage.info("removed 1 occurence of duplicate clients")
        }
    }

}
