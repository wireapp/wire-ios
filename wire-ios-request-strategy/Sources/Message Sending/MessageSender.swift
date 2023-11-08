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
    case missingMessageProtocol
    case missingGroupID
    case missingQualifiedID
    case missingMlsService
    case unresolvedApiVersion
    case messageExpired
}

public typealias SendableMessage = ProteusMessage & MLSMessage

// sourcery: AutoMockable
public protocol MessageSenderInterface {

    func sendMessage(message: any SendableMessage) async throws

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
        self.context = context
        self.messageDependencyResolver = messageDependencyResolver
    }

    private let apiProvider: APIProviderInterface
    private let context: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisherInterface
    private let messageDependencyResolver: MessageDependencyResolverInterface
    private let proteusPayloadProcessor = MessageSendingStatusPayloadProcessor()
    private let mlsPayloadProcessor = MLSMessageSendingStatusPayloadProcessor()

    public func sendMessage(message: any SendableMessage) async throws {
        WireLogger.messaging.debug("send message")

        // TODO: [jacob] we need to wait until we are "online"

        do {
            try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
            try await attemptToSend(message: message)
        } catch let networkError as NetworkError {
            if case .invalidRequestError(let responseFailure, _) = networkError, responseFailure.code == 533 {
                switch responseFailure.data?.type {
                case .federation:
                    responseFailure.updateExpirationReason(for: message, with: .federationRemoteError)
                case .unknown:
                    responseFailure.updateExpirationReason(for: message, with: .unknown)
                case .none:
                    break
                }
            }
            throw networkError
        } catch {
            WireLogger.messaging.debug("send message failed: \(error)")
            throw error
        }

        // Triggering request polling to re-evalute dependencies, other messages
        // might have been waiting for this message to be sent.
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    private func attemptToSend(message: any SendableMessage) async throws {
        let messageProtocol = await context.perform {message.conversation?.messageProtocol }

        guard let apiVersion = BackendInfo.apiVersion else { throw MessageSendError.unresolvedApiVersion }
        guard let messageProtocol else {
            throw MessageSendError.missingMessageProtocol
        }

        return switch messageProtocol {
        case .proteus:
            try await attemptToSendWithProteus(message: message, apiVersion: apiVersion)
        case .mls:
            try await attemptToSendWithMLS(message: message, apiVersion: apiVersion)
        }
    }

    private func attemptToSendWithProteus(message: any SendableMessage, apiVersion: APIVersion) async throws {
        let conversationID = await context.perform {
            message.conversation?.qualifiedID
        }

        guard let conversationID else {
            throw MessageSendError.missingQualifiedID
        }

        do {
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion).sendProteusMessage(
                message: message,
                conversationID: conversationID
            )
            await context.perform { [self] in
                handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
            }
        } catch let networkError as NetworkError {
            let missingClients = try await context.perform { [self] in
                try handleProteusFailure(message: message, networkError)
            }
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await sendMessage(message: message)
        }
    }

    private func handleProteusSuccess(message: any ProteusMessage, messageSendingStatus: Payload.MessageSendingStatus, response: ZMTransportResponse) {
        message.delivered(with: response) // FIXME: jacob refactor to not use raw response

        proteusPayloadProcessor.updateClientsChanges(
            from: messageSendingStatus,
            for: message
        )
    }

    private func handleProteusFailure(message: any ProteusMessage, _ failure: NetworkError) throws -> Set<QualifiedClientID> {
        switch failure {
        case .missingClients(let messageSendingStatus, _):
            proteusPayloadProcessor.updateClientsChanges(
                from: messageSendingStatus,
                for: message
            )
            context.enqueueDelayedSave()

            if message.isExpired {
                throw MessageSendError.messageExpired
            } else {
                return Set(messageSendingStatus.missing.qualifiedClientIDs)
            }
        default:
            if case .tryAgainLater = failure.response?.result {
                if message.isExpired {
                    throw MessageSendError.messageExpired
                } else {
                    return Set() // FIXME: [jacob] it's dangerous to retry indefinitely like this WPB-5454
                }
            } else {
                throw failure
            }
        }
    }

    private func attemptToSendWithMLS(message: any MLSMessage, apiVersion: APIVersion) async throws {
        let conversationID = await context.perform { message.conversation?.qualifiedID }
        let groupID = await context.perform { message.conversation?.mlsGroupID }
        let mlsService = await context.perform { self.context.mlsService }

        guard let conversationID else {
            throw MessageSendError.missingQualifiedID
        }
        guard let groupID else {
            throw MessageSendError.missingGroupID
        }
        guard let mlsService else {
            throw MessageSendError.missingMlsService
        }

        try await mlsService.commitPendingProposals(in: groupID)
        let encryptedData = try await encryptMlsMessage(message, groupID: groupID)
        let (payload, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
            .sendMLSMessage(message: encryptedData,
                            conversationID: conversationID,
                            expirationDate: await context.perform { message.expirationDate })

        await context.perform {
            self.mlsPayloadProcessor.updateFailedRecipients(from: payload, for: message)
            message.delivered(with: response)
        }
    }

    private func encryptMlsMessage(_ message: any MLSMessage, groupID: MLSGroupID) async throws -> Data {
        return try await context.perform {
            guard let mlsService = self.context.mlsService else {
                throw MessageSendError.missingMlsService
            }

            return try message.encryptForTransport { messageData in
                let encryptedBytes = try mlsService.encrypt(
                    message: messageData.bytes,
                    for: groupID
                )
                return encryptedBytes.data
            }
        }
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
