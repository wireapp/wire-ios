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
import WireSystem

// MARK: - ConversationDeletionError

public enum ConversationDeletionError: Error {
    case unknown, invalidOperation, conversationNotFound

    // MARK: Lifecycle

    init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (404, "no-conversation"?): self = .conversationNotFound
        case (400 ..< 499, _): self = .unknown
        default: return nil
        }
    }
}

extension ZMConversation {
    /// Delete a conversation remotely and locally for everyone
    ///
    /// Only team conversations can be deleted.
    public func delete(in userSession: ZMUserSession, completion: @escaping (Result<Void, Error>) -> Void) {
        delete(in: userSession.coreDataStack, transportSession: userSession.transportSession, completion: completion)
    }

    func delete(
        in contextProvider: ContextProvider,
        transportSession: TransportSessionType,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let removeLocalConversation = RemoveLocalConversationUseCase()

        guard
            ZMUser.selfUser(in: contextProvider.viewContext).canDeleteConversation(self),
            let conversationId = remoteIdentifier,
            let request = ConversationDeletionRequestFactory.requestForDeletingTeamConversation(self)
        else {
            return completion(.failure(ConversationDeletionError.invalidOperation))
        }

        request.add(ZMCompletionHandler(on: contextProvider.syncContext) { [weak contextProvider] response in
            guard let contextProvider else { return completion(.failure(ConversationDeletionError.unknown)) }

            if response.httpStatus == 200 {
                let conversation = ZMConversation.fetch(
                    with: conversationId,
                    domain: nil,
                    in: contextProvider.syncContext
                )

                guard let conversation else {
                    DispatchQueue.main.async {
                        completion(.success(()))
                    }
                    return
                }

                Task {
                    do {
                        try await removeLocalConversation.invoke(
                            with: conversation,
                            syncContext: contextProvider.syncContext
                        )
                        await MainActor.run {
                            completion(.success(()))
                        }
                    } catch {
                        WireLogger.mls.error("removeLocalConversation threw error: \(String(reflecting: error))")
                        await MainActor.run {
                            completion(.failure(error))
                        }
                    }
                }
            } else {
                let error = ConversationDeletionError(response: response) ?? .unknown
                Logging.network.debug("Error deleting converation: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        })

        transportSession.enqueueOneTime(request)
    }
}

// MARK: - ConversationDeletionRequestFactory

enum ConversationDeletionRequestFactory {
    static func requestForDeletingTeamConversation(_ conversation: ZMConversation) -> ZMTransportRequest? {
        guard
            let apiVersion = BackendInfo.apiVersion,
            let conversationId = conversation.remoteIdentifier,
            let teamRemoteIdentifier = conversation.teamRemoteIdentifier
        else { return nil }

        let path = "/teams/\(teamRemoteIdentifier.transportString())/conversations/\(conversationId.transportString())"

        return ZMTransportRequest(path: path, method: .delete, payload: nil, apiVersion: apiVersion.rawValue)
    }
}
