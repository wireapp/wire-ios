//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public enum EARServiceFactory {

    // MARK: - Public Interface

    /// Create a new `EARService`.
    ///
    /// - Parameters:
    ///   - accountID: The id of the self user.
    ///   - databaseContexts: The managed object contexts on which to set the `EARMessageEncryptionService`
    ///   - coreDataStack: The core data stack on which the `EARMessageEncryptionService` will be set.
    ///   - canPerformKeyMigration: Whether key migration can be performed. Key migration should not be performed when
    /// the service is running in app extensions.
    ///   - sharedUserDefaults:  The shared user defaults in which to keep track of whether EAR is enabled.
    ///   - authenticationContext: The authentication context used to access encryption keys.
    /// - Returns: a newly created `EARService` instance
    ///
    public static func createEARService(
        accountID: UUID,
        databaseContexts: [NSManagedObjectContext] = [],
        coreDataStack: CoreDataStackProtocol,
        canPerformKeyMigration: Bool = false,
        sharedUserDefaults: UserDefaults,
        authenticationContext: any AuthenticationContextProtocol
    ) async -> EARServiceInterface {
        let earStorage = EARStorage(userID: accountID, sharedUserDefaults: sharedUserDefaults)
        let messageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
        let migrator = EARMigrator(messageEncryptionService: messageEncryptionService)

        let earService = EARService(
            accountID: accountID,
            keyRepository: EARKeyRepository(),
            keyEncryptor: EARKeyEncryptor(),
            coreDataStack: coreDataStack,
            canPerformKeyMigration: canPerformKeyMigration,
            earStorage: earStorage,
            messageEncryptionService: messageEncryptionService,
            migrator: migrator,
            authenticationContext: authenticationContext
        )

        await internalSetupDatabaseContexts(
            databaseContexts: databaseContexts,
            onEARService: earService
        )

        return earService
    }

    // MARK: - Tests Interface

    #if DEBUG

        /// Synchronously creates an `EARService` instance
        ///
        /// - Parameters:
        ///   - accountID: The id of the self user.
        ///   - coreDataStack: The core data stack on which the `EARMessageEncryptionService` will be set.
        ///   - canPerformKeyMigration: Whether key migration can be performed. Key migration should not be performed
        /// when
        /// the service is running in app extensions.
        ///   - sharedUserDefaults: The shared user defaults in which to keep track of whether EAR is enabled.
        ///   - authenticationContext:  The authentication context used to access encryption keys.
        /// - Returns: a newly created `EARService` instance
        ///
        public static func createEARService(
            accountID: UUID,
            coreDataStack: CoreDataStackProtocol,
            canPerformKeyMigration: Bool = false,
            sharedUserDefaults: UserDefaults,
            authenticationContext: any AuthenticationContextProtocol
        ) -> EARService {
            let earStorage = EARStorage(userID: accountID, sharedUserDefaults: sharedUserDefaults)
            let messageEncryptionService = EARMessageEncryptionService(earStorage: earStorage)
            let migrator = EARMigrator(messageEncryptionService: messageEncryptionService)

            return EARService(
                accountID: accountID,
                keyRepository: EARKeyRepository(),
                keyEncryptor: EARKeyEncryptor(),
                coreDataStack: coreDataStack,
                canPerformKeyMigration: canPerformKeyMigration,
                earStorage: earStorage,
                messageEncryptionService: messageEncryptionService,
                migrator: migrator,
                authenticationContext: authenticationContext
            )
        }

        /// Sets the `EARMessageEncryptionService` on the given managed object contexts
        ///
        /// - Parameters:
        ///   - databaseContexts: The managed object contexts on which to set the `EARMessageEncryptionService`
        ///   - earService: The `EARService` instance to setup
        ///
        public static func setupDatabaseContexts(
            databaseContexts: [NSManagedObjectContext],
            onEARService earService: EARService
        ) async {
            await internalSetupDatabaseContexts(
                databaseContexts: databaseContexts,
                onEARService: earService
            )
        }

    #endif

    // MARK: - Private Helpers

    private static func internalSetupDatabaseContexts(
        databaseContexts: [NSManagedObjectContext],
        onEARService earService: EARService
    ) async {
        guard !databaseContexts.isEmpty else { return }

        await earService.setupDatabaseContexts(
            databaseContexts: databaseContexts
        )
    }
}
