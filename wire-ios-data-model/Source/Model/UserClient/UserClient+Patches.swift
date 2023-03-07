//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension UserClient {

    /// Migrate client sessions from using the client identifier only as session identifier
    /// to new client sessions  useing user identifier + client identifier as session identifier.
    /// These have less chances of collision.

    static func migrateAllSessionsClientIdentifiersV2(in moc: NSManagedObjectContext) {
        let request = UserClient.sortedFetchRequest()

        guard let allClients = moc.fetchOrAssert(request: request) as? [UserClient] else {
            // No clients? No migration needed.
            return
        }

        // Important:
        // If we're migrating from Cryptobox to Core Crypto, it's important that we
        // migrate the session ids before moving the session files into Core Crypto.
        //
        // However, we would only have an instance of `ProteusService` (backed by Core
        // Crypto) and not an instance of the `UserClientKeyStore` (backed by Cryptobox).
        //
        // Migration of the session ids relies on the keystore, so if we don't have an
        // instance if the keystore already, we create one temporarily for this migration
        // assuming that we'll perform the migration from Cryptobox to Core Crypto afterwards.

        let keyStore: UserClientKeysStore

        if let existingKeyStore = moc.zm_cryptKeyStore {
            keyStore = existingKeyStore
        } else {
            guard
                let accountDirectory = moc.accountDirectoryURL,
                let applicationContainer = moc.applicationContainerURL
            else {
                fatalError("Can not migration proteus session ids")
            }

            keyStore = UserClientKeysStore(
                accountDirectory: accountDirectory,
                applicationContainer: applicationContainer
            )
        }

        keyStore.encryptionContext.perform { session in
            for client in allClients {
                client.migrateSessionIdentifierFromV1IfNeeded(sessionDirectory: session)
                client.needsSessionMigration = false
            }
        }
    }

    // Problem:
    // Existing proteus sessions are qualified with user id and client id only. In a
    // federated environment, there is not the risk of id collisions, since in two
    // domains there possibly could be users that share the same user id and client id.
    //
    // Solution:
    // Migrate to V3 proteus session ids, which incorporate the domain.

    static func migrateAllSessionsClientIdentifiersV3(in moc: NSManagedObjectContext) {
        WireLogger.proteus.info("migrating all session ids to v3")

        let request = UserClient.sortedFetchRequest()

        guard let allClients = moc.fetchOrAssert(request: request) as? [UserClient] else {
            // No clients? No migration needed.
            WireLogger.proteus.info("migrating all session ids to v3: no clients to migrate")
            return
        }

        // Important:
        // If we're migrating from Cryptobox to Core Crypto, it's important that we
        // migrate the session ids before moving the session files into Core Crypto.
        //
        // However, we would only have an instance of `ProteusService` (backed by Core
        // Crypto) and not an instance of the `UserClientKeyStore` (backed by Cryptobox).
        //
        // Migration of the session ids relies on the keystore, so if we don't have an
        // instance if the keystore already, we create one temporarily for this migration
        // assuming that we'll perform the migration from Cryptobox to Core Crypto afterwards.

        let keyStore: UserClientKeysStore

        if let existingKeyStore = moc.zm_cryptKeyStore {
            WireLogger.proteus.info("migrating all session ids to v3: using existing keystore")
            keyStore = existingKeyStore
        } else {
            WireLogger.proteus.info("migrating all session ids to v3: creating temp keystore")

            guard
                let accountDirectory = moc.accountDirectoryURL,
                let applicationContainer = moc.applicationContainerURL
            else {
                fatalError("Can not migration proteus session ids")
            }

            keyStore = UserClientKeysStore(
                accountDirectory: accountDirectory,
                applicationContainer: applicationContainer
            )
        }

        keyStore.encryptionContext.perform { session in
            for client in allClients {
                client.migrateSessionIdentifierFromV2IfNeeded(sessionDirectory: session)
                client.needsSessionMigration = false
            }
        }
    }

}
