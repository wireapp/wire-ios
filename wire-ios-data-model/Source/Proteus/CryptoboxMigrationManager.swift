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
import WireSystem

// MARK: - CryptoboxMigrationManagerInterface

// sourcery: AutoMockable
public protocol CryptoboxMigrationManagerInterface {
    func isMigrationNeeded(accountDirectory: URL) -> Bool

    func performMigration(
        accountDirectory: URL,
        coreCrypto: SafeCoreCryptoProtocol
    ) async throws
}

// MARK: - CryptoboxMigrationManager

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
        coreCrypto: SafeCoreCryptoProtocol
    ) async throws {
        do {
            WireLogger.proteus.info("migrating cryptobox data...")
            let cryptoboxDirectory = fileManager.cryptoboxDirectory(in: accountDirectory)
            try await coreCrypto.perform { try await $0.proteusCryptoboxMigrate(path: cryptoboxDirectory.path) }
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

    // MARK: - Helpers

    private func removeDirectory(in accountDirectory: URL) throws {
        let cryptoboxDirectory = fileManager.cryptoboxDirectory(in: accountDirectory)
        guard fileManager.fileExists(atPath: cryptoboxDirectory.path) else { return }
        try fileManager.removeItem(at: cryptoboxDirectory)
    }
}

// MARK: - FileManagerInterface

// sourcery: AutoMockable
protocol FileManagerInterface {
    func fileExists(atPath path: String) -> Bool
    func removeItem(at url: URL) throws
    func cryptoboxDirectory(in accountDirectory: URL) -> URL
}

// MARK: - FileManager + FileManagerInterface

extension FileManager: FileManagerInterface {
    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        FileManager.keyStoreURL(
            accountDirectory: accountDirectory,
            createParentIfNeeded: false
        )
    }
}
