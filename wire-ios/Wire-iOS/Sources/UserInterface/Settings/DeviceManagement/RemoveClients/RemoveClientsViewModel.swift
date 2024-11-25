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

import WireCommonComponents
import WireSyncEngine

extension RemoveClientsViewController {
    final class ViewModel: NSObject {
        private let removeUserClientUseCase: RemoveUserClientUseCaseProtocol?
        private(set) var clients: [UserClient] = []

        init(clientsList: [UserClient]) {
            self.removeUserClientUseCase = ZMUserSession.shared()?.removeUserClient

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

        func removeUserClient(_ userClient: UserClient, password: String) async throws {
            let clientId = await userClient.managedObjectContext?.perform {
                userClient.remoteIdentifier
            }
            guard let clientId else {
                throw RemoveUserClientError.clientDoesNotExistLocally
            }

            try await removeUserClientUseCase?.invoke(
                clientId: clientId,
                password: password
            )
        }
    }
}
