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

import Foundation
import WireCoreCrypto
import WireLegacyLogging
import WireSystem

public struct CoreCryptoConfiguration {

    public let path: String
    public let key: Data
    public let clientID: WireCoreCryptoUniffi.ClientId
}

public class CoreCryptoConfigProvider {

    // MARK: - Properties

    private let coreCryptoKeyProvider: CoreCryptoKeyProvider
    private let coreCryptoPathComponent = "corecrypto"

    // MARK: - Life cycle

    public init(coreCryptoKeyProvider: CoreCryptoKeyProvider) {
        self.coreCryptoKeyProvider = coreCryptoKeyProvider
    }

    // MARK: - Configuration

    public func createInitialConfiguration(
        sharedContainerURL: URL,
        userID: UUID,
        createKeyIfNeeded: Bool
    ) async throws -> (path: String, key: Data) {

        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: userID,
            applicationContainer: sharedContainerURL
        )

        try FileManager.default.createAndProtectDirectory(at: accountDirectory)
        let coreCryptoDirectory = accountDirectory.appendingPathComponent(coreCryptoPathComponent)

        do {
            let key = try await coreCryptoKeyProvider.coreCryptoKey(
                createIfNeeded: createKeyIfNeeded,
                path: coreCryptoDirectory.path
            )
            return (
                path: coreCryptoDirectory.path,
                key: key
            )
        } catch {
            WireLogger.coreCrypto.error(
                "Failed to get core crypto key: \(String(describing: error))",
                attributes: .safePublic
            )
            throw ConfigurationSetupFailure.failedToGetCoreCryptoKey
        }
    }

    public enum ConfigurationSetupFailure: Error, Equatable {
        case failedToGetClientId
        case failedToGetCoreCryptoKey
    }
}
