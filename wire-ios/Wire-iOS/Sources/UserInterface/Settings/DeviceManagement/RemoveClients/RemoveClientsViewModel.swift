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

import WireCommonComponents
import WireSyncEngine

extension RemoveClientsViewController {
    final class ViewModel: NSObject {
        private(set) var clients: [UserClient] = []

        init(clientsList: [UserClient]) {
            super.init()
            initalizeProperties(clientsList)
        }

        private func initalizeProperties(_ clientsList: [UserClient]) {
            clients = clientsList
                .filter { !$0.isSelfClient() }
                .sorted(by: {
                    guard
                        let leftDate = $0.activationDate,
                        let rightDate = $1.activationDate
                    else {
                        return false
                    }
                    return leftDate.compare(rightDate) == .orderedDescending
                })
        }

        @MainActor
        func removeUserClient(_ userClient: UserClient, password: String?) async throws {
            let clientId = await userClient.managedObjectContext?.perform {
                userClient.remoteIdentifier
            }
            guard let clientId else {
                throw RemoveUserClientError.clientDoesNotExistLocally
            }

            // There's a race condition where we need to remove a client after
            // login and the user session doesn't exist yet (at init of this view).
            // So create the use case as late as possible. (Ideally we don't use
            // this static accessor).
            let useCase = ZMUserSession.shared()?.removeUserClient

            try await useCase?.invoke(
                clientId: clientId,
                password: password
            )
        }
    }
}
