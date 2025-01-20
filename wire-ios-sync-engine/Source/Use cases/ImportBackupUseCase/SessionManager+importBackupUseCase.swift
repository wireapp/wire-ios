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

public extension SessionManager {

    func importBackupUseCase(
        fileArchiver: ImportBackupFileArchiverProtocol,
        entityStorage: ImportBackupEntityStorageProtocol,
        appStateUpdater: ImportBackupAppStateUpdaterProtocol
    ) -> ImportBackupUseCaseProtocol? {

        // return `nil` immediately if there is no active user session
        activeUserSession.map { _ in

            ImportBackupUseCase(
                userSession: { [weak self] in self?.activeUserSession },
                dispatchGroup: dispatchGroup,
                fileArchiver: fileArchiver,
                entityStorage: entityStorage,
                appStateUpdater: appStateUpdater,
                sharedContainerURL: sharedContainerURL,
                logger: .localStorage
            )
        }
    }
}
