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
import CoreCryptoSwift

public struct CoreCryptoConfiguration {

    public let path: String
    public let key: String
    public let clientID: String

    func clientIDBytes() -> ClientId? {
        return clientID.data(using: .utf8)?.bytes
    }

}

public class CoreCryptoFactory {

    // MARK: - Properties

    private let sharedContainerURL: URL
    private let selfUser: ZMUser
    private let coreCryptoKeyProvider: CoreCryptoKeyProvider

    // MARK: - Life cycle

    public init(
        sharedContainerURL: URL,
        selfUser: ZMUser,
        coreCryptoKeyProvider: CoreCryptoKeyProvider = .init()
    ) {
        self.sharedContainerURL = sharedContainerURL
        self.selfUser = selfUser
        self.coreCryptoKeyProvider = coreCryptoKeyProvider
    }

    // MARK: - Types

    public enum ConfigurationError: Error, Equatable {

        case failedToGetClientId
        case failedToGetCoreCryptoKey

    }

    // MARK: - Methods

    public func createConfiguration() throws -> CoreCryptoConfiguration {
        guard let qualifiedClientId = MLSQualifiedClientID(user: selfUser).qualifiedClientId else {
            throw ConfigurationError.failedToGetClientId
        }

        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: selfUser.remoteIdentifier,
            applicationContainer: sharedContainerURL
        )

        FileManager.default.createAndProtectDirectory(at: accountDirectory)
        let coreCryptoDirectory = accountDirectory.appendingPathComponent("corecrypto")

        do {
            let key = try coreCryptoKeyProvider.coreCryptoKey()
            return CoreCryptoConfiguration(
                path: coreCryptoDirectory.path,
                key: key.base64EncodedString(),
                clientID: qualifiedClientId
            )
        } catch {
            Logging.mls.warn("Failed to get core crypto key \(String(describing: error))")
            throw ConfigurationError.failedToGetCoreCryptoKey
        }
    }


    public func createCoreCrypto(with config: CoreCryptoConfiguration) throws -> CoreCryptoProtocol {
        guard let clientID = config.clientIDBytes() else {
            throw ConfigurationError.failedToGetClientId
        }

        return try CoreCrypto(
            path: config.path,
            key: config.key,
            clientId: clientID,
            entropySeed: nil
        )
    }

}
