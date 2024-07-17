//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCoreCrypto
import WireSystem

public struct CoreCryptoConfiguration {

    public let path: String
    public let key: String
    public let clientID: String

    public var clientIDBytes: ClientId? {
        .init(from: clientID)
    }

}

public class CoreCryptoConfigProvider {
    private let sqliteDirectory = "cc"
    private let sqliteFilename = "corecrypto"

    // MARK: - Properties

    private let coreCryptoKeyProvider: CoreCryptoKeyProvider

    // MARK: - Life cycle

    public init(coreCryptoKeyProvider: CoreCryptoKeyProvider = .init()) {
        self.coreCryptoKeyProvider = coreCryptoKeyProvider
    }

    // MARK: - Configuration

    public func createFullConfiguration(
        sharedContainerURL: URL,
        selfUser: ZMUser,
        createKeyIfNeeded: Bool
    ) throws -> CoreCryptoConfiguration {

        let qualifiedClientID = try clientID(of: selfUser)

        let initialConfig = try createInitialConfiguration(
            sharedContainerURL: sharedContainerURL,
            userID: selfUser.remoteIdentifier,
            createKeyIfNeeded: createKeyIfNeeded
        )

        return CoreCryptoConfiguration(
            path: initialConfig.path,
            key: initialConfig.key,
            clientID: qualifiedClientID
        )
    }

    public func createInitialConfiguration(
        sharedContainerURL: URL,
        userID: UUID,
        createKeyIfNeeded: Bool
    ) throws -> (path: String, key: String) {

        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: userID,
            applicationContainer: sharedContainerURL
        )

        let coreCryptoDirectory = accountDirectory.appendingPathComponent(sqliteDirectory)
        try FileManager.default.createAndProtectDirectory(at: coreCryptoDirectory)

        let coreCryptoFile = coreCryptoDirectory.appendingPathComponent(sqliteFilename)

        try movePreviousCoreCryptoFilesIfNeeded(from: accountDirectory, to: coreCryptoDirectory)
        
        FileManager.default.enumerator(atPath: accountDirectory.path)?.forEach({ file in
            WireLogger.coreCrypto.debug("🕵🏽 file: \(file)")
        })

        do {
            let key = try coreCryptoKeyProvider.coreCryptoKey(createIfNeeded: createKeyIfNeeded)
            return (
                path: coreCryptoFile.path,
                key: key.base64EncodedString()
            )
        } catch {
            WireLogger.coreCrypto.error("Failed to get core crypto key \(String(describing: error))")
            throw ConfigurationSetupFailure.failedToGetCoreCryptoKey
        }
    }

    private func movePreviousCoreCryptoFilesIfNeeded(from oldDirURL: URL, to currentDirURL: URL) throws {
        WireLogger.coreCrypto.debug("🕵🏽 movePreviousCoreCryptoFileIfNeeded start")
        let walFilename = "\(sqliteFilename)-wal"
        let shmFilename = "\(sqliteFilename)-shm"

        for file in [walFilename, shmFilename, sqliteFilename] {
            let oldPath = oldDirURL.appendingPathComponent(file).path
            let newPath = currentDirURL.appendingPathComponent(file).path

            guard FileManager.default.fileExists(atPath: oldPath) else {
                continue
            }

            WireLogger.coreCrypto.debug("moving cc file \(oldPath) to \(newPath)")
            do {
                try FileManager.default.moveItem(atPath: oldPath, toPath: currentDirURL.path)
            } catch {
                WireLogger.coreCrypto.warn("could not move cc file \(oldPath) to \(newPath)")
            }
        }

        WireLogger.coreCrypto.debug("🕵🏽 movePreviousCoreCryptoFileIfNeeded end")
    }

    public func clientID(of selfUser: ZMUser) throws -> String {
        guard
            let selfClient = selfUser.selfClient(),
            let clientID = MLSClientID(userClient: selfClient)?.rawValue
        else {
            throw ConfigurationSetupFailure.failedToGetClientId
        }

        return clientID
    }

    public enum ConfigurationSetupFailure: Error, Equatable {
        case failedToGetClientId
        case failedToGetCoreCryptoKey
    }
}

public extension ClientId {

    init?(from string: String) {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        self = data
    }

}
