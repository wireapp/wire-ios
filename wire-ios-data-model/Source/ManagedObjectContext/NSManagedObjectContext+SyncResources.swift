//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

// This contains some methods to pass the information through the persistence store metadata
// that we need a sync resources after
public extension NSManagedObjectContext {

    private var migrationsNeedToSyncResourcesKey: String {
        "migrationsNeedToSyncResources"
    }

    internal enum migrationsNeedToSyncResourcesError: Error {
        case couldNotPersistMetadata
    }

    /// use to trigger sync resources after some CoreData migrations
    func setMigrationNeedsSyncResources() throws {
        setPersistentStoreMetadata(1, key: migrationsNeedToSyncResourcesKey)
        if !makeMetadataPersistent() {
            throw MigrationNeedsSlowSyncError.couldNotPersistMetadata
        }
    }

    /// checks if we need a syncResources after migrations
    func readMigrationNeedsSyncResourcesFlag() -> Bool {
        let value = (persistentStoreMetadata(forKey: migrationsNeedToSyncResourcesKey) as? Int) ?? 0
        return value == 1
    }

    /// Reset migration needs syncResources flag
    func resetMigrationNeedsSyncResoucesFlagIfNeeded() {
        if readMigrationNeedsSyncResourcesFlag() {
            setPersistentStoreMetadata(Int?.none, key: migrationsNeedToSyncResourcesKey)
        }
    }
}
