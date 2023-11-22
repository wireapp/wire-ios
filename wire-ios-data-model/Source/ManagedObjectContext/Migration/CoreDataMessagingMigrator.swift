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
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion)
}

final class CoreDataMessagingMigrator: CoreDataMessagingMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        let metadata: [String: Any]?

        if #available(iOSApplicationExtension 15.0, *) {
            metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: storeURL)
        } else {
            metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
        }

        guard let metadata else {
            return false
        }

        return compatibleVersionForStoreMetadata(metadata) != version
    }
    
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) {
        fatalError("not implemented")
    }

    // MARK: - Helpers

    private func compatibleVersionForStoreMetadata(_ metadata: [String : Any]) -> CoreDataMessagingMigrationVersion? {
        let allVersions = CoreDataMessagingMigrationVersion.allCases
        let compatibleVersion = allVersions.first {
            let bundle = Bundle(for: CoreDataMessagingMigrator.self)
            let subdirectory = "zmessaging.momd"

            guard let url = bundle.url(forResource: $0.rawValue, withExtension: "omo", subdirectory: subdirectory) else {
                return false
            }

            let model = NSManagedObjectModel(contentsOf: url)
            return model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == true
        }

        return compatibleVersion
    }
}
