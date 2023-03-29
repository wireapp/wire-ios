//
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

import Foundation
import WireSystem

enum CryptoboxMigrationError: Error {
    case failedToMigrateData
    case failedToDeleteLegacyData
}

protocol CryptoboxMigration {
    func isNeeded(in accountDirectory: URL) -> Bool
    func perform(in accountDirectory: URL, syncContext: NSManagedObjectContext) throws
}

class CryptoboxMigrationManager: CryptoboxMigration {

    func isNeeded(in accountDirectory: URL) -> Bool {
        guard DeveloperFlag.proteusViaCoreCrypto.isOn else { return false }

        let cryptoboxDirectory = getDirectory(in: accountDirectory)
        let cryptoboxDirectoryExists = FileManager.default.fileExists(atPath: cryptoboxDirectory.path)
        return cryptoboxDirectoryExists
    }

    func perform(
        in accountDirectory: URL,
        syncContext: NSManagedObjectContext
    ) throws {
            guard let proteusService = syncContext.proteusService else {
                WireLogger.proteus.warn("cannot perform cryptobox migration without proteus service")
                precondition(syncContext.proteusService != nil, "proteusService is expected to be availble")
                return
            }

            do {
                WireLogger.proteus.info("migrating cryptobox data...")
                let cryptoboxDirectory = getDirectory(in: accountDirectory)
                try proteusService.migrateCryptoboxSessions(at: cryptoboxDirectory)
                WireLogger.proteus.info("migrating cryptobox data... success")
            } catch {
                throw CryptoboxMigrationError.failedToMigrateData
            }

            do {
                WireLogger.proteus.info("removing legacy cryptobox data...")
                try removeDirectory(in: accountDirectory)
                WireLogger.proteus.info("removing legacy cryptobox data... success")
            } catch {
                throw CryptoboxMigrationError.failedToDeleteLegacyData
            }
    }

    // MARK: - Helpers

    private func getDirectory(in accountDirectory: URL) -> URL {
        return FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: false)
    }

    private func removeDirectory(in accountDirectory: URL) throws {
        let cryptoboxDirectory = getDirectory(in: accountDirectory)

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: cryptoboxDirectory.path) {
            try fileManager.removeItem(at: cryptoboxDirectory)
        }
    }

}
