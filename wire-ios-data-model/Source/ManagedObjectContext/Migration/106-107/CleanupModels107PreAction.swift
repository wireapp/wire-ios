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

/// Removes UserClient duplicates and invalid ParticipantRoles
class CleanupModels107PreAction: CoreDataMigrationAction {

    private enum Keys: String {
        case conversation
        case needsToBeUpdatedFromBackend
    }

    override func execute(in context: NSManagedObjectContext) throws {

        try removeInvalidParticipantRoles(in: context)
        try removeUserClientDuplicates(in: context)
    }

    private func removeInvalidParticipantRoles(in context: NSManagedObjectContext) throws {
        let entityName = ParticipantRole.entityName()
        // we don't want to load the ParticipantRole model here just plain NSManagedObject in case of changes in future
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "%K == nil", Keys.conversation.rawValue)

        let result = try context.fetch(request)
        for object in result {
            WireLogger.localStorage.warn("remove zombie object 'ParticipantRole' without conversation", attributes: .safePublic)
            context.delete(object)
        }
    }

    private func removeUserClientDuplicates(in context: NSManagedObjectContext) throws {

        WireLogger.localStorage.info("beginning duplicate clients migration", attributes: .safePublic)

        let duplicates: [String: [NSManagedObject]] = context.findDuplicated(
            entityName: UserClient.entityName(),
            by: #keyPath(UserClient.remoteIdentifier)
        )

        WireLogger.localStorage.info("found (\(duplicates.count)) occurences of duplicate clients", attributes: .safePublic)

        duplicates.forEach { (_, clients: [NSManagedObject]) in
            guard clients.count > 1 else {
                return
            }

            clients.first?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            clients.dropFirst().forEach(context.delete)
            WireLogger.localStorage.info("removed 1 occurence of duplicate clients", attributes: .safePublic)
        }
    }
}
