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

public enum MessageSendError: Error, Equatable {
    case messageProtocolMissing
    case unresolvedApiVersion
    case missingSelfClient
    case messageExpired
    case securityLevelDegraded
    case networkError(NetworkError)
}

public typealias SendableMessage = ProteusMessage & MLSMessage

// sourcery: AutoMockable
public protocol MessageSenderInterface {

    func sendMessage(message: any SendableMessage) async -> Swift.Result<Void, MessageSendError>

}

public class MessageSender: MessageSenderInterface {

    public init (
        apiProvider: APIProviderInterface,
        clientRegistrationDelegate: ClientRegistrationDelegate,
        sessionEstablisher: SessionEstablisherInterface,
        messageDependencyResolver: MessageDependencyResolverInterface,
        context: NSManagedObjectContext
    ) {
        self.apiProvider = apiProvider
        self.clientRegistrationDelegate = clientRegistrationDelegate
        self.sessionEstablisher = sessionEstablisher
        self.managedObjectContext = context
        self.messageDependencyResolver = messageDependencyResolver
    }

    private let apiProvider: APIProviderInterface
    private let managedObjectContext: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisherInterface
    private let messageDependencyResolver: MessageDependencyResolverInterface
    private let processor = MessageSendingStatusPayloadProcessor()

    public func sendMessage(message: any SendableMessage) async -> Swift.Result<Void, MessageSendError> {
        WireLogger.messaging.debug("send message")

        // TODO: [jacob] we need to wait until we are "online"

        return await messageDependencyResolver.waitForDependenciesToResolve(for: message)
            .mapError { dependencyError in
                switch dependencyError {
                case .securityLevelDegraded:
                    MessageSendError.securityLevelDegraded
                }
            }
            .flatMapAsync { _ in
                await attemptToSend(message: message)
                    .map({ success in
                        // Triggering request polling to re-evalute dependencies, other messages
                        // might have been waiting for this message to be sent.
                        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
                        return success
                    })
            }
            .mapError { error in
                WireLogger.messaging.debug("send message failed: \(error)")
                return error
            }
    }

    private func attemptToSend(message: any SendableMessage) async -> Swift.Result<Void, MessageSendError> {
        guard let apiVersion = BackendInfo.apiVersion else { return .failure(MessageSendError.unresolvedApiVersion)}
        guard let messageProtocol = await managedObjectContext.perform({
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

    private func attemptToSendWithProteus(message: any SendableMessage, apiVersion: APIVersion) async -> Swift.Result<Void, MessageSendError> {
        guard let conversationID = await managedObjectContext.perform({
            message.conversation?.qualifiedID
        }) else {
            return .failure(MessageSendError.messageProtocolMissing)
        }

        let result = await apiProvider.messageAPI(apiVersion: apiVersion).sendProteusMessage(
            message: message,
            conversationID: conversationID
        )

        return switch result {
        case .success((let messageSendingStatus, let response)):
            await managedObjectContext.perform {
                self.handleProteusSuccess(
                    message: message,
                    messageSendingStatus: messageSendingStatus,
                    response: response)
            }
        case .failure(let networkError):
            await (await managedObjectContext.perform {
                self.handleProteusFailure(message: message, networkError)
            }).flatMapAsync { missingClients in
                await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
                    .mapError({ error in
                        switch error {
                        case .missingSelfClient: MessageSendError.missingSelfClient
                        case .networkError(let networkError): MessageSendError.networkError(networkError)
                        }
                    })
                    .flatMapAsync { _ in
                        await sendMessage(message: message)
                    }
            }
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
            processor.updateClientsChanges(
                from: messageSendingStatus,
                for: message
            )
            managedObjectContext.enqueueDelayedSave()

            if message.isExpired {
                return .failure(MessageSendError.messageExpired)
            } else {
                return .success(Set(messageSendingStatus.missing.qualifiedClientIDs))
            }
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
            if case .tryAgainLater = failure.response?.result {
                if message.isExpired {
                    return .failure(MessageSendError.messageExpired)
                } else {
                    return .success(Set()) // FIXME: [jacob] it's dangerous to retry indefinitely like this WPB-5454
                }
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

private extension Payload.ClientListByQualifiedUserID {

    var qualifiedClientIDs: [QualifiedClientID] {
        var qualifiedClientIDs: [QualifiedClientID] = []
        for (domain, clientListByUserID) in self {
            for (userID, clientIDs) in clientListByUserID {
                if let userUuid = UUID(uuidString: userID) {
                    qualifiedClientIDs.append(
                        contentsOf: clientIDs.map { clientID in
                            QualifiedClientID(
                                userID: userUuid,
                                domain: domain,
                                clientID: clientID)
                        }
                    )
                }
            }
        }
        return qualifiedClientIDs
    }

}
