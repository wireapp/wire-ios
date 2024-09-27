//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel

/// Provides debug actions for UserClientDetails
struct UserClientDeveloperItemsProvider: DeveloperToolsContextItemsProvider {
    // MARK: Lifecycle

    init?(context: DeveloperToolsContext) {
        guard let userClient = context.currentUserClient else {
            return nil
        }
        self.userClient = userClient
    }

    // MARK: Internal

    let userClient: UserClient
    let logger = WireLogger.system

    func getActionItems() -> [DeveloperToolsViewModel.Item] {
        typealias ButtonItem = DeveloperToolsViewModel.ButtonItem
        return [
            .button(ButtonItem(title: "Delete Device", action: { Task { await deleteDevice() } })),
            .button(ButtonItem(title: "Duplicate Session", action: { Task { await duplicateClient() } })),
            .button(ButtonItem(title: "Corrupt Session", action: { Task { await corruptSession() } })),
        ]
    }

    @MainActor
    func deleteDevice() async {
        let clientObjectID = userClient.objectID
        guard let sync = userClient.managedObjectContext?.zm_sync else {
            return
        }
        do {
            guard let client = try await sync.perform({ try sync.existingObject(with: clientObjectID) as? UserClient })
            else {
                return
            }
            await client.deleteClientAndEndSession()
            _ = await sync.perform { sync.saveOrRollback() }
        } catch {
            logger.error(error.localizedDescription)
        }
    }

    @MainActor
    func corruptSession() async {
        guard let sync = userClient.managedObjectContext?.zm_sync,
              let selfClientObjectID = ZMUser.selfUser()?.selfClient()?.objectID else {
            return
        }
        let userClientObjectID = userClient.objectID
        do {
            guard let client = try await sync
                .perform({ try sync.existingObject(with: userClientObjectID) as? UserClient }),
                let selfClient = try await sync
                .perform({ try sync.existingObject(with: selfClientObjectID) as? UserClient }) else {
                return
            }
            _ = await selfClient.establishSessionWithClient(
                client,
                usingPreKey: "pQABAQACoQBYIBi1nXQxPf9hpIp1K1tBOj/tlBuERZHfTMOYEW38Ny7PA6EAoQBYIAZbZQ9KtsLVc9VpHkPjYy2+Bmz95fyR0MGKNUqtUUi1BPY="
            )
            _ = await sync.perform { sync.saveOrRollback() }
        } catch {
            WireLogger.e2ei.debug(error.localizedDescription)
        }
    }

    @MainActor
    func duplicateClient() {
        guard let context = userClient.managedObjectContext?.zm_sync else {
            return
        }
        context.performAndWait {
            guard
                let userID = userClient.user?.remoteIdentifier,
                let domain = userClient.user?.domain ?? BackendInfo.domain
            else {
                return
            }

            let user = ZMUser.fetch(
                with: userID,
                domain: domain,
                in: context
            )

            let duplicate = UserClient.insertNewObject(in: context)
            duplicate.remoteIdentifier = userClient.remoteIdentifier
            duplicate.user = user

            context.saveOrRollback()
        }
    }
}
