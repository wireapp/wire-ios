////
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

import CoreData

class RemoveZombieParticipantRolesMigrationPolicy: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        if
            sInstance.entity.name == ParticipantRole.entityName(),
            sInstance.primitiveValue(forKey: "conversation") == nil
        {
            // drop zombie object without conversation
            // TODO:  log in zmLogger?
            WireLogger.localStorage.info("remove zombie object 'ParticipantRole' without conversation")
        } else {
            try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
        }
    }
}
