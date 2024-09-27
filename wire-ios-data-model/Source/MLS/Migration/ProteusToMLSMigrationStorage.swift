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

// MARK: - ProteusToMLSMigrationStorageInterface

// sourcery: AutoMockable
protocol ProteusToMLSMigrationStorageInterface {
    var migrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus { get set }
}

// MARK: - ProteusToMLSMigrationStorage

class ProteusToMLSMigrationStorage: ProteusToMLSMigrationStorageInterface {
    // MARK: Lifecycle

    init(
        userID: UUID,
        userDefaults: UserDefaults
    ) {
        self.storage = PrivateUserDefaults(
            userID: userID,
            storage: userDefaults
        )
    }

    // MARK: Internal

    typealias MigrationStatus = ProteusToMLSMigrationCoordinator.MigrationStatus

    // MARK: - Interface

    var migrationStatus: MigrationStatus {
        get {
            let value = storage.integer(forKey: Key.migrationStatus)
            return MigrationStatus(rawValue: value)!
        }

        set {
            storage.set(newValue.rawValue, forKey: Key.migrationStatus)
        }
    }

    // MARK: Private

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case migrationStatus = "com.wire.mls.migration.status"
    }

    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>
}
