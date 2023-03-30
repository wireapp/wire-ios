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

public protocol CryptoboxMigrationManagerInterface {

    func isMigrationNeeded(accountDirectory: URL) -> Bool

    func performMigration(
        accountDirectory: URL,
        syncContext: NSManagedObjectContext
    ) throws

    func completeMigration(syncContext: NSManagedObjectContext) throws

}

public class CryptoboxMigrationManager: CryptoboxMigrationManagerInterface {

    // MARK: - Properties

    let fileManager: FileManagerInterface

    // MARK: - Life cycle

    public convenience init() {
        self.init(fileManager: FileManager.default)
    }

    init(fileManager: FileManagerInterface) {
        self.fileManager = fileManager
    }

    // MARK: - Failure

    enum Failure: Error {

        case failedToMigrateData
        case failedToDeleteLegacyData
        case proteusServiceUnavailable

    }

    // MARK: - Methods

    public func isMigrationNeeded(accountDirectory: URL) -> Bool {
        guard DeveloperFlag.proteusViaCoreCrypto.isOn else { return false }
        let cryptoboxDirectory = fileManager.cryptoboxDirectory(in: accountDirectory)
        return fileManager.fileExists(atPath: cryptoboxDirectory.path)
    }

    public func performMigration(
        accountDirectory: URL,
        syncContext: NSManagedObjectContext
    ) throws {
            guard let proteusService = syncContext.proteusService else {
                WireLogger.proteus.warn("cannot perform cryptobox migration without proteus service")
                throw Failure.proteusServiceUnavailable
            }

            do {
                WireLogger.proteus.info("migrating cryptobox data...")
                let cryptoboxDirectory = fileManager.cryptoboxDirectory(in: accountDirectory)
                try proteusService.migrateCryptoboxSessions(at: cryptoboxDirectory)
                WireLogger.proteus.info("migrating cryptobox data... success")
            } catch {
                throw Failure.failedToMigrateData
            }

            do {
                WireLogger.proteus.info("removing legacy cryptobox data...")
                try removeDirectory(in: accountDirectory)
                WireLogger.proteus.info("removing legacy cryptobox data... success")
            } catch {
                throw Failure.failedToDeleteLegacyData
            }
    }

    public func completeMigration(syncContext: NSManagedObjectContext) throws {
        guard DeveloperFlag.proteusViaCoreCrypto.isOn else {
            return
        }

        guard let proteusService = syncContext.proteusService else {
            throw Failure.proteusServiceUnavailable
        }

        try proteusService.completeInitialization()
    }

    // MARK: - Helpers

    private func removeDirectory(in accountDirectory: URL) throws {
        let cryptoboxDirectory = fileManager.cryptoboxDirectory(in: accountDirectory)
        guard fileManager.fileExists(atPath: cryptoboxDirectory.path) else { return }
        try fileManager.removeItem(at: cryptoboxDirectory)
    }

}

protocol FileManagerInterface {

    func fileExists(atPath path: String) -> Bool
    func removeItem(at url: URL) throws
    func cryptoboxDirectory(in accountDirectory: URL) -> URL

}

extension FileManager: FileManagerInterface {

    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        return FileManager.keyStoreURL(
            accountDirectory: accountDirectory,
            createParentIfNeeded: false
        )
    }

}
