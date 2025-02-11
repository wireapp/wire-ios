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

import WireDomainPkg
import WireLogging

public extension SessionManager {

    var importBackupUseCase: ImportBackupUseCaseProtocol? {

        // return `nil` immediately if there is no active user session
        activeUserSession.map { _ in

            ImportBackupUseCase(
                userSession: { [weak self] in self?.activeUserSession },
                dispatchGroup: dispatchGroup,
                streamDecryptor: ImportBackupStreamDecryptor(),
                fileArchiver: ImportBackupFileArchiver(),
                entityStorage: ImportBackupEntityStorage(),
                appStateUpdater: ImportBackupAppStateUpdater(sessionManager: self),
                sharedContainerURL: sharedContainerURL,
                logger: .localStorage
            )
        }
    }
}

private struct ImportBackupAppStateUpdater: ImportBackupAppStateUpdaterProtocol {

    let sessionManager: SessionManager

    @MainActor
    func reportMigrationNeeded() async {
        await withCheckedContinuation { continuation in
            sessionManager.prepareForRestoreWithMigration(completion: continuation.resume)
        }

        var maxWaitIterations = 10
        while !CoreDataStack.stacks.isEmpty, maxWaitIterations > 0 {
            maxWaitIterations -= 1
            WireLogger.sessionManager.debug("Waiting for CoreDataStack.stacks to be empty")
            WireLogger.sessionManager.debug("sessionManager.backgroundUserSessions: \(sessionManager.backgroundUserSessions)")
            try! await Task.sleep(for: .milliseconds(600))
        }
    }

    @MainActor
    func selectAccountAndTriggerSlowSync(_ account: Account) async {
        let userSession = await withCheckedContinuation { continuation in
            sessionManager.select(account, completion: { continuation.resume(returning: $0) })
        }
        guard let userSession else { return }
        userSession.syncManagedObjectContext.performGroupedBlock {
            userSession.syncStatus.forceSlowSync()
        }
    }
}
