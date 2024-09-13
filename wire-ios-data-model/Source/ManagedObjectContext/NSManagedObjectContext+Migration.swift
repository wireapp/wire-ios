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

// This contains some methods to pass the information through the persistence store metadata
// that we need a slow sync after
extension NSManagedObjectContext {
    private var migrationsNeedToSlowSyncKey: String {
        "migrationsNeedToSlowSync"
    }

    enum MigrationNeedsSlowSyncError: Error {
        case couldNotPersistMetadata
    }

    /// use to trigger slow sync after some CoreData migrations
    public func setMigrationNeedsSlowSync() throws {
        setPersistentStoreMetadata(1, key: migrationsNeedToSlowSyncKey)
        if !makeMetadataPersistent() {
            throw MigrationNeedsSlowSyncError.couldNotPersistMetadata
        }
    }

    /// checks if we need a slowSync after migrations
    /// - Note: this cleans up after reading the value
    public func readAndResetSlowSyncFlag() -> Bool {
        let value = (persistentStoreMetadata(forKey: migrationsNeedToSlowSyncKey) as? Int) ?? 0
        setPersistentStoreMetadata(Int?.none, key: migrationsNeedToSlowSyncKey)
        return value == 1
    }
}
