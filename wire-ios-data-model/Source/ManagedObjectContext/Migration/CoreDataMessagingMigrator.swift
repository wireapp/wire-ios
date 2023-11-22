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

protocol CoreDataMessagingMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) async
}

enum CoreDataMessagingMigratorError: Error {
    case missingStoreURL
}

final class CoreDataMessagingMigrator: CoreDataMessagingMigratorProtocol {

    let isInMemoryStore: Bool

    init(isInMemoryStore: Bool) {
        self.isInMemoryStore = isInMemoryStore
    }

    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        let metadata: [String: Any]?

        if #available(iOSApplicationExtension 15.0, *) {
            let type: NSPersistentStore.StoreType = isInMemoryStore ? .inMemory : .sqlite
            metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(type: type, at: storeURL)
        } else {
            let type = isInMemoryStore ? NSInMemoryStoreType : NSSQLiteStoreType
            metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type, at: storeURL)
        }

        guard let metadata else {
            return false
        }

        return compatibleVersionForStoreMetadata(metadata) != version
    }
    
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) async {
        fatalError("not implemented")
    }

    // MARK: - Helpers

    private func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> CoreDataMessagingMigrationVersion? {
        let allVersions = CoreDataMessagingMigrationVersion.allCases
        let compatibleVersion = allVersions.first {
            guard let url = $0.managedObjectModelURL() else {
                return false
            }

            let model = NSManagedObjectModel(contentsOf: url)
            return model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == true
        }

        return compatibleVersion
    }
}
