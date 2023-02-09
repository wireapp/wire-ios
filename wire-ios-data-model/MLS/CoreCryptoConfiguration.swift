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
    public let clientId: String

    public init(path: String, key: String, clientId: String) {
        self.path = path
        self.key = key
        self.clientId = clientId
    }
}

public class CoreCryptoFactory {

    private let coreCryptoKeyProvider: CoreCryptoKeyProvider

    public convenience init() {
        self.init(coreCryptoKeyProvider: CoreCryptoKeyProvider())
    }

    init(coreCryptoKeyProvider: CoreCryptoKeyProvider) {
        self.coreCryptoKeyProvider = coreCryptoKeyProvider
    }

    public enum ConfigurationError: Error, Equatable {
        case failedToGetClientId
        case failedToGetCoreCryptoKey
    }

    public func coreCrypto(
        sharedContainerURL: URL,
        syncContext: NSManagedObjectContext
    ) throws -> CoreCryptoProtocol {

        let configuration = try configuration(
            sharedContainerURL: sharedContainerURL,
            syncContext: syncContext
        )

        return try coreCrypto(configuration: configuration)
    }

    public func coreCrypto(configuration: CoreCryptoConfiguration) throws -> CoreCryptoProtocol {
        guard let clientId = configuration.clientIDBytes() else {
            throw ConfigurationError.failedToGetClientId
        }

        return try CoreCrypto(
            path: configuration.path,
            key: configuration.key,
            clientId: clientId,
            entropySeed: nil
        )
    }

    public func configuration(sharedContainerURL: URL, syncContext: NSManagedObjectContext) throws -> CoreCryptoConfiguration {
        precondition(syncContext.zm_isSyncContext)

        let selfUser = ZMUser.selfUser(in: syncContext)

        guard let qualifiedClientId = MLSQualifiedClientID(user: selfUser).qualifiedClientId else {
            throw ConfigurationError.failedToGetClientId
        }

        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: selfUser.remoteIdentifier,
            applicationContainer: sharedContainerURL
        )
        FileManager.default.createAndProtectDirectory(at: accountDirectory)
        let mlsDirectory = accountDirectory.appendingMLSFolder()

        do {
            let key = try coreCryptoKeyProvider.coreCryptoKey()
            return CoreCryptoConfiguration(
                path: mlsDirectory.path,
                key: key.base64EncodedString(),
                clientId: qualifiedClientId
            )
        } catch {
            Logging.mls.warn("Failed to get core crypto key \(String(describing: error))")
            throw ConfigurationError.failedToGetCoreCryptoKey
        }
    }

}

public extension CoreCryptoConfiguration {
    func clientIDBytes() -> ClientId? {
        return clientId.base64EncodedBytes
    }
}

private extension URL {
    func appendingMLSFolder() -> URL {
        return appendingPathComponent("mls")
    }
}
