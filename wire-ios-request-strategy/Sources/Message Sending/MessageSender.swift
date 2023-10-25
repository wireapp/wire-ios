////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

// FIXME: [jacob] use existing packages
extension Swift.Result {
    func flatMapAsync<NewSuccess>(_ transform: (Success) async -> Swift.Result<NewSuccess, Failure>) async -> Swift.Result<NewSuccess, Failure> {
        switch self {
        case .success(let success):
            return await transform(success)
        case .failure(let failure):
            return .failure(failure)
        }
    }
}

public protocol HttpClient {

    func send(_ request: ZMTransportRequest) async -> ZMTransportResponse

}

public class HttpClientImpl: HttpClient {

    let transportSession: TransportSessionType
    let queue: ZMSGroupQueue

    public init(transportSession: TransportSessionType, queue: ZMSGroupQueue) {
        self.transportSession = transportSession
        self.queue = queue
    }

    public func send(_ request: ZMTransportRequest) async -> ZMTransportResponse {
        await withCheckedContinuation { continuation in
            request.add(ZMCompletionHandler(on: queue, block: { response in
                continuation.resume(returning: response)
            }))

            transportSession.enqueueOneTime(request)
        }
    }
}

enum MessageSendError: Error {
    case messageProtocolMissing
    case unresolvedApiVersion
    case missingPrecondition
    case networkError(NetworkError)
}

typealias Message = ProteusMessage & MLSMessage

public class MessageSender {

    public init (
        apiProvider: APIProvider,
        clientRegistrationDelegate: ClientRegistrationDelegate,
        sessionEstablisher: SessionEstablisher,
        context: NSManagedObjectContext
    ) {
        self.apiProvider = apiProvider
        self.clientRegistrationDelegate = clientRegistrationDelegate
        self.sessionEstablisher = sessionEstablisher
        self.managedObjectContext = context
    }

    private let apiProvider: APIProvider
    private let managedObjectContext: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisher
    private let processor = MessageSendingStatusPayloadProcessor()

    func sendMessage(message: any Message) async -> Swift.Result<Void, MessageSendError> {
        // FIXME: [jacob] wait for message dependencies to resolve
        // FIXME: [jacob] check that message hasn't expired

        return await attemptToSend(message: message)
    }

    private func attemptToSend(message: any Message) async -> Swift.Result<Void, MessageSendError> {
        guard let apiVersion = BackendInfo.apiVersion else { return .failure(MessageSendError.unresolvedApiVersion)}
        guard let messageProtocol = managedObjectContext.performAndWait({
            message.conversation?.messageProtocol
        }) else {
            return .failure(MessageSendError.messageProtocolMissing)
        }

        return switch messageProtocol {
        case .proteus:
            await attemptToSendWithProteus(message: message, apiVersion: apiVersion)

        case .mls:
            await attemptToSendWithMLS(message: message, apiVersion: apiVersion)
        }
    }

    private func attemptToSendWithProteus(message: any ProteusMessage, apiVersion: APIVersion) async -> Swift.Result<Void, MessageSendError> {
        guard let conversationID = managedObjectContext.performAndWait({
            message.conversation?.qualifiedID
        }) else {
            return .failure(MessageSendError.messageProtocolMissing)
        }

        let result = await apiProvider.messageAPI(apiVersion: apiVersion).sendProteusMessage(
            payload: message,
            conversationID: conversationID
        )

        return switch result {
        case .success((let messageSendingStatus, let response)):
            managedObjectContext.performAndWait {
                handleProteusSuccess(
                    message: message,
                    messageSendingStatus: messageSendingStatus,
                    response: response)
            }
        case .failure(let networkError):
            await managedObjectContext.performAndWait {
                handleProteusFailure(message: message, networkError)
            }.flatMapAsync { missingClients in
                await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
                    .mapError({ error in
                        switch error {
                        case .missingSelfClient: MessageSendError.missingPrecondition
                        case .networkError(let networkError): MessageSendError.networkError(networkError)
                        }
                    })
                    .flatMapAsync { _ in
                        await attemptToSendWithProteus(message: message, apiVersion: apiVersion)
                    }
            }
        }
    }

    private func missingClients() -> Set<QualifiedClientID> {
        return managedObjectContext.performAndWait {
            let clients = ZMUser.selfUser(in: managedObjectContext).selfClient()?.missingClients ?? Set()
            return Set(clients.compactMap({ $0.qualifiedClientID })) // FIXME: [jacob] we can't do compact map
        }
    }

    private func handleProteusSuccess(message: any ProteusMessage, messageSendingStatus: Payload.MessageSendingStatus, response: ZMTransportResponse) -> Swift.Result<Void, MessageSendError> {
        message.delivered(with: response) // FIXME: jacob refactor to not use raw response

        processor.updateClientsChanges(
            from: messageSendingStatus,
            for: message
        )

        return .success(Void())
    }

    private func handleProteusFailure(message: any ProteusMessage, _ failure: NetworkError) -> Swift.Result<Set<QualifiedClientID>, MessageSendError> {
        switch failure {
        case .missingClients(let messageSendingStatus, _):
            let missingClients = processor.updateClientsChanges(
                from: messageSendingStatus,
                for: message
            ).flatMap(\.value)
            let qualifiedClientIDs = missingClients.compactMap({ $0.qualifiedClientID })

            guard
                missingClients.count == qualifiedClientIDs.count
            else {
                return .failure(MessageSendError.missingPrecondition)
            }
            return .success(Set(qualifiedClientIDs))
        case .invalidRequestError(let responseFailure, _):
            switch (responseFailure.code, responseFailure.label) {
            case (533, _):
                guard
                    let data = responseFailure.data
                else {
                    return .failure(MessageSendError.networkError(failure))
                }

                switch data.type {
                case .federation:
                    responseFailure.updateExpirationReason(for: message, with: .federationRemoteError)
                case .unknown:
                    responseFailure.updateExpirationReason(for: message, with: .unknown)
                }

                return .failure(MessageSendError.networkError(failure))
            default:
                return .failure(MessageSendError.networkError(failure))
            }
        default:
            if case .permanentError = failure.response?.result {
                return .success(Set()) // FIXME: [jacob] it's dangerous to retry indefinitely like this
            } else {
                return .failure(MessageSendError.networkError(failure))
            }
        }
    }

    private func attemptToSendWithMLS(message: any MLSMessage, apiVersion: APIVersion) async -> Swift.Result<Void, MessageSendError> {
        return .failure(MessageSendError.messageProtocolMissing)
    }
}

private extension UserClient {

    var qualifiedClientID: QualifiedClientID? {
        guard
            let clientID = remoteIdentifier,
            let qualifiedID = user?.qualifiedID
        else {
            return nil
        }
        return QualifiedClientID(userID: qualifiedID.uuid, domain: qualifiedID.domain, clientID: clientID)
    }

}
