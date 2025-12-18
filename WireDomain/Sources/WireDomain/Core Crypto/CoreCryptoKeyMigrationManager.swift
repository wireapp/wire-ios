//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireCoreCrypto
import WireDataModel
import WireLogging

public class CoreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol {

    private let journal: Journal

    public init(journal: Journal) {
        self.journal = journal
    }

    // MARK: Journal updates

    public var isAnyMigrationRequired: Bool {
        isKeyRotationNeeded || isMigrationToBytesNeeded || isMigrationToScopedKeyNeeded
    }

    public var isMigrationToBytesNeeded: Bool {
        journal[.isCoreCryptoKeyMigrationToBytesRequired]
    }

    public var isMigrationToScopedKeyNeeded: Bool {
        journal[.isCoreCryptoKeyMigrationToScopedKeyRequired]
    }

    public var isKeyRotationNeeded: Bool {
        journal[.isCoreCryptoKeyRotationRequired]
    }

    public func markMigrationToBytesAsSkipped() {
        WireLogger.coreCrypto.info("Skip core crypto key migration", attributes: .safePublic)

        journal[.isCoreCryptoKeyMigrationToBytesRequired] = false
    }

    public func markMigrationToScopedKeyDone() {
        WireLogger.coreCrypto.info("Marking migration to scoped key as done")

        journal[.isCoreCryptoKeyMigrationToScopedKeyRequired] = false
    }

    public func markKeyRotationAsDone() {
        WireLogger.coreCrypto.info("Marking key rotation as done")

        journal[.isCoreCryptoKeyRotationRequired] = false
    }

    // MARK: Migrations

    public func migrateDatabaseKeyToBytes(path: String, oldKey: String, newKey: Data) async throws {
        WireLogger.coreCrypto.info(
            "Core crypto key migration from string to bytes is required",
            attributes: .safePublic
        )

        try await migrateDatabaseKeyTypeToBytes(
            path: path,
            oldKey: oldKey,
            newKey: DatabaseKey(key: newKey)
        )
        journal[.isCoreCryptoKeyMigrationToBytesRequired] = false

        WireLogger.coreCrypto.info("Core crypto key is migrated to bytes successfully", attributes: .safePublic)
    }

    public func updateKey(path: String, oldKey: Data, newKey: Data) async throws {
        do {
            try await updateDatabaseKey(
                name: path,
                oldKey: DatabaseKey(key: oldKey),
                newKey: DatabaseKey(key: newKey)
            )
        } catch {
            throw CoreCryptoKeyMigrationManagerError.failedToUpdateKey(underlyingError: error)
        }
    }

}
