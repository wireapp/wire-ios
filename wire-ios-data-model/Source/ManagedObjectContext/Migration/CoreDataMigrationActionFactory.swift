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

enum CoreDataMigrationActionFactory {

    static func createPreMigrationAction<Version: CoreDataMigrationVersion>(for destinationVersion: Version) -> CoreDataMigrationAction? {

        if let version = destinationVersion as? CoreDataMessagingMigrationVersion {
            return createPreMigrationAction(for: version)
        }

        if let version = destinationVersion as? CoreDataEventsMigrationVersion {
            return createPreMigrationAction(for: version)
        }

        fatalError("unsupported coredata migration version")
    }

    static func createPostMigrationAction<Version: CoreDataMigrationVersion>(for destinationVersion: Version) -> CoreDataMigrationAction? {

        if let version = destinationVersion as? CoreDataMessagingMigrationVersion {
            return createPostMigrationAction(for: version)
        }

        if let version = destinationVersion as? CoreDataEventsMigrationVersion {
            return createPostMigrationAction(for: version)
        }

        fatalError("unsupported coredata migration version")
    }

    // MARK: - CoreDataMessagingMigrationVersion

    static func createPreMigrationAction(for destinationVersion: CoreDataMessagingMigrationVersion) -> CoreDataMigrationAction? {
        switch destinationVersion {
        case .v111:
            return RemoveDuplicatePreAction()

        case .v107:
            return CleanupModels107PreAction()

        default:
            return nil
        }
    }

    static func createPostMigrationAction(for destinationVersion: CoreDataMessagingMigrationVersion) -> CoreDataMigrationAction? {
        switch destinationVersion {
        case .v119:
            return FixDuplicateOneOnOneConversationsAction()

        case .v116:
            return IsPendingInitialFetchMigrationAction()

        case .v114:
            return OneOnOneConversationMigrationAction()

        case .v111:
            return PrefillPrimaryKeyAction()

        default:
            return nil
        }
    }

    // MARK: - CoreDataEventsMigrationVersion

    static func createPreMigrationAction(for destinationVersion: CoreDataEventsMigrationVersion) -> CoreDataMigrationAction? {
        return nil
    }

    static func createPostMigrationAction(for destinationVersion: CoreDataEventsMigrationVersion) -> CoreDataMigrationAction? {
        return nil
    }
}
