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
import LocalAuthentication

protocol EARServiceInterface {

    func generateKeys() throws -> Data
    func fetchPublicKeys() -> (primary: SecKey, secondary: SecKey)?
    func fetchPrivateKeys() -> (primary: SecKey?, secondary: SecKey?)
    func fetchDatabaseKey() -> VolatileData?

}

public class EARService: EARServiceInterface {

    // MARK: - Properties

    private let accountID: UUID
    private let keyRepository: EARKeyRepositoryInterface

    private let primaryPublicKeyDescription: PublicEARKeyDescription
    private let primaryPrivateKeyDescription: PrivateEARKeyDescription
    private let secondaryPublicKeyDescription: PublicEARKeyDescription
    private let secondaryPrivateKeyDescription: PrivateEARKeyDescription
    private let databaseKeyDescription: DatabaseEARKeyDescription

    // MARK: - Life cycle

    init(
        accountID: UUID,
        keyRepository: EARKeyRepositoryInterface = EARKeyRepository()
    ) {
        self.accountID = accountID
        self.keyRepository = keyRepository

        primaryPublicKeyDescription = .primaryKeyDescription(accountID: accountID)
        primaryPrivateKeyDescription = .primaryKeyDescription(accountID: accountID)
        secondaryPublicKeyDescription = .secondaryKeyDescription(accountID: accountID)
        secondaryPrivateKeyDescription = .secondaryKeyDescription(accountID: accountID)
        databaseKeyDescription = .keyDescription(accountID: accountID)
    }

    // MARK: - Keys

    func generateKeys() throws -> Data {
        let primaryPublicKey: SecKey
        let secondaryPublicKey: SecKey
        let databaseKey: Data

        do {
            let identifier = primaryPublicKeyDescription.uniqueIdentifier
            let keyPair = try KeychainManager.generatePublicPrivateKeyPair(identifier: identifier)
            primaryPublicKey = keyPair.publicKey
        } catch {
            // TODO: log error
            throw error
        }

        do {
            let identifier = primaryPrivateKeyDescription.uniqueIdentifier
            let keyPair = try KeychainManager.generatePublicPrivateKeyPair(identifier: identifier)
            secondaryPublicKey = keyPair.publicKey
        } catch {
            // TODO: log error
            throw error
        }

        do {
            databaseKey = try KeychainManager.generateKey(numberOfBytes: 32)
        } catch {
            // TODO: log error
            throw error
        }

        do {
            try keyRepository.storePublicKey(
                description: primaryPublicKeyDescription,
                key: primaryPublicKey
            )

            try keyRepository.storePublicKey(
                description: secondaryPublicKeyDescription,
                key: secondaryPublicKey
            )

            // TODO: encrypt database key
            try keyRepository.storeDatabaseKey(
                description: databaseKeyDescription,
                key: databaseKey
            )
        } catch {
            // TODO: log error, maybe try to delete any keys that were stored
            throw error
        }

        return databaseKey
    }

    func fetchPublicKeys() -> (primary: SecKey, secondary: SecKey)? {
        do {
            let primary = try keyRepository.fetchPublicKey(description: primaryPublicKeyDescription)
            let secondary = try keyRepository.fetchPublicKey(description: secondaryPublicKeyDescription)
            return (primary, secondary)
        } catch {
            // TODO: log
            return nil
        }
    }

    // TODO: allow adding a context
    func fetchPrivateKeys() -> (primary: SecKey?, secondary: SecKey?) {
        let primary = try? keyRepository.fetchPrivateKey(description: primaryPrivateKeyDescription)
        let secondary = try? keyRepository.fetchPrivateKey(description: secondaryPrivateKeyDescription)
        return (primary, secondary)
    }

    // TODO: decrypt
    func fetchDatabaseKey() -> VolatileData? {
        let data = try? keyRepository.fetchDatabaseKey(description: databaseKeyDescription)
        return data.map(VolatileData.init)
    }

}

extension PublicEARKeyDescription {

    static func primaryKeyDescription(accountID: UUID) -> PublicEARKeyDescription {
        return PublicEARKeyDescription(
            accountID: accountID,
            label: "primary-public"
        )
    }

    static func secondaryKeyDescription(accountID: UUID) -> PublicEARKeyDescription {
        return PublicEARKeyDescription(
            accountID: accountID,
            label: "secondary-public"
        )
    }

}

extension PrivateEARKeyDescription {

    static func primaryKeyDescription(
        accountID: UUID,
        context: LAContext? = nil,
        authenticationPrompt: String? = nil
    ) -> PrivateEARKeyDescription {
        return PrivateEARKeyDescription(
            accountID: accountID,
            label: "primary-private",
            context: context,
            prompt: authenticationPrompt
        )
    }

    static func secondaryKeyDescription(accountID: UUID) -> PrivateEARKeyDescription {
        return PrivateEARKeyDescription(
            accountID: accountID,
            label: "secondary-private"
        )
    }

}

extension DatabaseEARKeyDescription {

    static func keyDescription(accountID: UUID) -> DatabaseEARKeyDescription {
        return DatabaseEARKeyDescription(
            accountID: accountID,
            label: "database"
        )
    }

}
