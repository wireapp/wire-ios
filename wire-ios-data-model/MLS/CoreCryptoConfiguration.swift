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
import CoreCrypto

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

    private let coreCryptoKeyProvider: CoreCryptoKeyProvider

    // MARK: - Life cycle

    public init(coreCryptoKeyProvider: CoreCryptoKeyProvider = .init()) {
        self.coreCryptoKeyProvider = coreCryptoKeyProvider
    }

    // MARK: - Configuration

    public func createConfiguration(
        sharedContainerURL: URL,
        selfUser: ZMUser
    ) throws -> CoreCryptoConfiguration {
        guard let qualifiedClientId = MLSQualifiedClientID(user: selfUser).qualifiedClientId else {
            throw ConfigurationSetupFailure.failedToGetClientId
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
            throw ConfigurationSetupFailure.failedToGetCoreCryptoKey
        }
    }

    public enum ConfigurationSetupFailure: Error, Equatable {
        case failedToGetClientId
        case failedToGetCoreCryptoKey
    }

    // MARK: - Core Crypto

    public func createCoreCrypto(with config: CoreCryptoConfiguration) throws -> SafeCoreCryptoProtocol {
        guard let clientID = config.clientIDBytes() else {
            throw CoreCryptoSetupFailure.failedToGetClientIDBytes
        }

        let coreCrypto = try CoreCryptoWrapper(
            path: config.path,
            key: config.key,
            clientId: clientID,
            entropySeed: nil
        )

        return SafeCoreCrypto(coreCrypto: coreCrypto, coreCryptoConfiguration: config)
    }

    public enum CoreCryptoSetupFailure: Error, Equatable {
        case failedToGetClientIDBytes
    }

}
