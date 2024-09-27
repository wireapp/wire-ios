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
import WireCoreCrypto
import WireSystem

// MARK: - CoreCryptoConfiguration

public struct CoreCryptoConfiguration {
    public let path: String
    public let key: String
    public let clientID: String

    public var clientIDBytes: ClientId? {
        .init(from: clientID)
    }
}

// MARK: - CoreCryptoConfigProvider

public class CoreCryptoConfigProvider {
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

        try FileManager.default.createAndProtectDirectory(at: accountDirectory)
        let coreCryptoDirectory = accountDirectory.appendingPathComponent("corecrypto")

        do {
            let key = try coreCryptoKeyProvider.coreCryptoKey(createIfNeeded: createKeyIfNeeded)
            return (
                path: coreCryptoDirectory.path,
                key: key.base64EncodedString()
            )
        } catch {
            WireLogger.coreCrypto.error("Failed to get core crypto key \(String(describing: error))")
            throw ConfigurationSetupFailure.failedToGetCoreCryptoKey
        }
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

extension ClientId {
    public init?(from string: String) {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        self = data
    }
}
