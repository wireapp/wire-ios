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

/// Policy to migrate ZMUser and ZMConversation duplicate objects
class DuplicateObjectsMigrationPolicy: NSEntityMigrationPolicy {

    private enum Keys: String {
        case needsToBeUpdatedFromBackend
        case primaryKey
    }

    private var keyCache = Set<String>()
    private var duplicateOccurences: [String: Int] = [:]

    // method to populate primaryKey called after createDestinationInstances on all occurences of ZMUser or ZMConversation
    @objc(primaryKey::)
    func primaryKey(_ remoteIdentifierData: Data?, domain: String?) -> String {
       return ZMManagedObject.primaryKey(from: remoteIdentifierData.flatMap(UUID.init(data: )), domain: domain)
    }

    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        // Get the primary key for sInstance
        let primaryKey = self.primaryKey(fromSourceInstance: sInstance)

        if keyCache.contains(primaryKey) {
            duplicateOccurences[primaryKey] = (duplicateOccurences[primaryKey] ?? 0) + 1
            WireLogger.localStorage.debug("skips the duplicate instance \(duplicateOccurences)")
            // skips the duplicate instance
            return
        } else {
            // create the dInstance
            try super.createDestinationInstances(forSource: sInstance, in: mapping, manager: manager)
            // mark it needing update
            let dInstance = manager.destinationInstances(forEntityMappingName: mapping.name, sourceInstances: [sInstance]).first
            dInstance?.setValue(true, forKey: Keys.needsToBeUpdatedFromBackend.rawValue)
            keyCache.insert(primaryKey)
        }
    }

    override func endInstanceCreation(forMapping mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        for (key, count) in duplicateOccurences {
            WireLogger.localStorage.info("Dropped \(count) occurences of type \(mapping.sourceEntityName ?? "<nil>") for id: \(key)")
        }

        if duplicateOccurences.count > 0 {
            markNeedsSlowSync(manager: manager,
                              forEntityName: mapping.sourceEntityName ?? "<nil>")
        }
    }

    func primaryKey(fromSourceInstance sInstance: NSManagedObject) -> String {
        let uuidData = sInstance.value(forKey: ZMManagedObject.remoteIdentifierDataKey()!) as? Data
        let domain = sInstance.value(forKey: ZMManagedObject.domainKey()!) as? String
        return self.primaryKey(uuidData, domain: domain)
    }

    private func markNeedsSlowSync(manager: NSMigrationManager, forEntityName entityName: String) {
        do {
            try manager.destinationContext.setMigrationNeedsSlowSync()
        } catch {
            WireLogger.localStorage.error("Failed to trigger slow sync on migration \(entityName): \(error.localizedDescription)")
        }
    }
}
