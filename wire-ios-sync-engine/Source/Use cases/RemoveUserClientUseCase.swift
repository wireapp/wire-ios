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

// sourcery: AutoMockable
public protocol RemoveUserClientUseCaseProtocol {

    func invoke(clientId: String, password: String) async throws

}

class RemoveUserClientUseCase: RemoveUserClientUseCaseProtocol {

    // MARK: - Properties

    private let userClientAPI: UserClientAPI
    private let syncContext: NSManagedObjectContext

    // MARK: - Life cycle

    init(
        userClientAPI: UserClientAPI,
        syncContext: NSManagedObjectContext) {
            self.userClientAPI = userClientAPI
            self.syncContext = syncContext
        }

    // MARK: - Public interface

    func invoke(clientId: String, password: String) async throws {
        let userClient = await syncContext.perform {
            return UserClient.fetchExistingUserClient(with: clientId, in: self.syncContext)
        }
        guard let userClient else {
            throw RemoveUserClientError.clientDoesNotExistLocally
        }

        do {
            try await userClientAPI.deleteUserClient(clientId: clientId, password: password)
            await didDeleteClient(userClient)

        } catch let networkError as NetworkError {
            try await handleFailure(networkError, userClient: userClient)
        }
    }

    // MARK: - Helpers

    private func didDeleteClient(_ userClient: UserClient) async {
        await userClient.deleteClientAndEndSession()
        await ZMClientUpdateNotification.notifyDeletionCompleted(
            remainingClients: selfUserClientsExcludingSelfClient,
            context: syncContext)
    }

    private var selfUserClientsExcludingSelfClient: [UserClient] {
        get async {
            return await syncContext.perform {
                let selfUser = ZMUser.selfUser(in: self.syncContext)
                let selfClient = selfUser.selfClient()
                let remainingClients = selfUser.clients.filter { $0 != selfClient && !$0.isZombieObject }
                return Array(remainingClients)
            }
        }
    }

    private func handleFailure(_ failure: NetworkError, userClient: UserClient) async throws {
        switch failure {
        case .invalidRequestError(let failureResponse, _):
            switch failureResponse.label {
            case .clientNotFound:
                // the client existed locally but not remotely, we delete it locally
                syncContext.delete(userClient)
                syncContext.saveOrRollback()

                throw RemoveUserClientError.clientToDeleteNotFound

            case .invalidCredentials, .missingAuth, .badRequest:
                throw RemoveUserClientError.invalidCredentials

            default:
                throw failure
            }

        default:
            throw failure
        }
    }
}

public enum RemoveUserClientError: Error {

    case clientToDeleteNotFound
    case clientDoesNotExistLocally
    case invalidCredentials

}
