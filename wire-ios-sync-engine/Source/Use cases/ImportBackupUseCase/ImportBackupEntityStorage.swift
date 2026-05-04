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

import Foundation

struct ImportBackupEntityStorage: ImportBackupEntityStorageProtocol {

    var importsDirectory: URL {
        CoreDataStack.importsDirectory
    }

    @MainActor
    func replacePersistentStore(
        accountIdentifier: UUID,
        from backupDirectory: URL,
        applicationContainer: URL
    ) async throws -> URL {
        try await CoreDataStack.importLocalStorage(
            accountIdentifier: accountIdentifier,
            from: backupDirectory,
            applicationContainer: applicationContainer
        )
    }

    @MainActor
    func createContextProvider(
        account: Account,
        applicationContainer: URL,
        dispatchGroup: ZMSDispatchGroup?,
        localDomain: String?,
        isFederationEnabled: Bool
    ) async throws -> any ContextProvider {

        let stack = CoreDataStack(
            account: account,
            applicationContainer: applicationContainer,
            dispatchGroup: dispatchGroup,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        try await stack.load()
        return stack

    }

}
