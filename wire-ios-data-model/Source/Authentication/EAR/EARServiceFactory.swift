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

public struct EARServiceFactory {

    public init() {}

    public func createEARService(
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

        if !databaseContexts.isEmpty {
            await earService.setupDatabaseContexts(
                databaseContexts: databaseContexts
            )
        }

        return earService
    }

}
