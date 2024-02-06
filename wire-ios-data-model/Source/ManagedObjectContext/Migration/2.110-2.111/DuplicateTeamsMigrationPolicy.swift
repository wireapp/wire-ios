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
import WireSystem

class DuplicateTeamsMigrationPolicy: NSEntityMigrationPolicy {

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
    }

    private let zmLog = ZMSLog(tag: "core-data")

    override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
        zmLog.safePublic("beginning duplicate teams migration", level: .info)
        WireLogger.localStorage.info("beginning duplicate teams migration")

        let context = manager.sourceContext

        let duplicates: [Data: [NSManagedObject]] = context.findDuplicated(
            entityName: Team.entityName(),
            by: Team.remoteIdentifierDataKey()!
        )

        zmLog.safePublic(SanitizedString(stringLiteral: "found (\(duplicates.count)) occurences of duplicate teams"), level: .info)
        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate teams")

        duplicates.forEach { (_, teams: [NSManagedObject]) in
            guard teams.count > 1 else {
                return
            }
           
            // for now we just keep one team and mark to sync and drop the rest.
            teams.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            teams.dropFirst().forEach(context.delete)

            zmLog.safePublic("removed 1 occurence of duplicate teams", level: .warn)
            WireLogger.localStorage.info("removed 1 occurence of duplicate teams")
        }
    }

}
