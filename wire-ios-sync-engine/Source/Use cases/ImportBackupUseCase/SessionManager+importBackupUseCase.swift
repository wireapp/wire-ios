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

public import Foundation

import WireFoundation
import WireUtilitiesPackage
import WireLogging

public extension SessionManager {

    func importLegacyBackupUseCase(url: URL) -> ImportBackupUseCaseProtocol? {

        // return `nil` immediately if there is no active user session
        activeUserSession.map { _ in

            ImportLegacyBackupUseCase(
                url: url,
                userSession: { [weak self] in self?.activeUserSession },
                dispatchGroup: dispatchGroup,
                streamDecryptor: ImportLegacyBackupStreamDecryptor(),
                fileUnarchiver: ImportBackupFileArchiver(),
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
    }

    @MainActor
    func selectAccountAndTriggerSlowSync(_ account: Account) async {
        let userSession = await withCheckedContinuation { continuation in
            sessionManager.select(account, completion: { continuation.resume(returning: $0) })
        }
        guard let userSession else { return }
        do {
            try await userSession.syncAgent?.performInitialSync()
        } catch {
            WireLogger.sync.error("error performing slow sync: \(String(describing: error))", attributes: .initialSync, .safePublic)
        }
    }
}
