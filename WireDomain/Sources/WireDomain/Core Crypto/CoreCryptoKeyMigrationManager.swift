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

    public var isMigrationNeeded: Bool {
        journal[.isCoreCryptoKeyMigrationRequired]
    }

    public func performMigrationIfNeeded(path: String, oldKey: String, newKey: Data) async throws {
        if isMigrationNeeded {
            WireLogger.coreCrypto.info("Core crypto key migration is required")

            try await migrateDatabaseKeyTypeToBytes(path: path, oldKey: oldKey, newKey: newKey)
            journal[.isCoreCryptoKeyMigrationRequired] = false

            WireLogger.coreCrypto.info("Core crypto key is migrated successfully")
        }
    }

    public func markMigrationAsSkipped() {
        WireLogger.coreCrypto.info("Skip core crypto key migration")

        journal[.isCoreCryptoKeyMigrationRequired] = false
    }

}
