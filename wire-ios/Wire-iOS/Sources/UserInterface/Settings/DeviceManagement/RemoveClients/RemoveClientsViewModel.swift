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

import WireSyncEngine
import WireCommonComponents

extension RemoveClientsViewController {
    final class ViewModel: NSObject {
        private var clients: [UserClient] = [] {
            didSet {
                self.sortedClients = self.clients.sorted(by: {
                    guard let leftDate = $0.activationDate, let rightDate = $1.activationDate else { return false }
                    return leftDate.compare(rightDate) == .orderedDescending
                })
            }
        }
        private var removeUserClientUseCase: RemoveUserClientUseCaseProtocol?

        var sortedClients: [UserClient] = []
        var credentials: ZMEmailCredentials?

        init(clientsList: [UserClient],
             credentials: ZMEmailCredentials?) {
            self.credentials = credentials
            self.removeUserClientUseCase = ZMUserSession.shared()?.removeUserClient

            super.init()
            self.initalizeProperties(clientsList)
        }

        private func initalizeProperties(_ clientsList: [UserClient]) {
            self.clients = clientsList.filter { !$0.isSelfClient() }
        }

        func removeUserClient(_ userClient: UserClient) async throws {
            try await removeUserClientUseCase?.invoke(userClient, credentials: credentials?.emailCredentials)
        }
    }
}

extension ZMEmailCredentials {
    var emailCredentials: EmailCredentials {
        return EmailCredentials(email: email, password: password)
    }
}
