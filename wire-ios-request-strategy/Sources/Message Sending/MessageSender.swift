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

enum MessageTarget {
    case Users(usersIds: [QualifiedID])
    case Clients(recipients: [QualifiedClientID])
    case Conversation(usersToIgnore: Set<QualifiedID>)
}

enum MessageSendError: Error {
    case messageProtocolMissing
    case unresolvedApiVersion
    case failedToGenerateRequest
    case failedToParseResponse
    case gaveUpRetrying
}

typealias Message = ProteusMessage & MLSMessage

public class MessageSender {

    public init (
        httpClient: HttpClient,
        clientRegistrationDelegate: ClientRegistrationDelegate,
        sessionEstablisher: SessionEstablisher,
        context: NSManagedObjectContext
    ) {
        self.httpClient = httpClient
        self.clientRegistrationDelegate = clientRegistrationDelegate
        self.sessionEstablisher = sessionEstablisher
        self.managedObjectContext = context
    }

    private let httpClient: HttpClient
    private let managedObjectContext: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisher
    private let requestFactory = ClientMessageRequestFactory()
    private let processor = MessageSendingStatusPayloadProcessor()

    func sendMessage(message: any Message) async -> Swift.Result<Void, MessageSendError> {
        // FIXME: [jacob] wait for message dependencies to resolve

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
        guard let conversation = managedObjectContext.performAndWait({
            message.conversation
        }) else {
            return .failure(MessageSendError.messageProtocolMissing)
        }
        guard let request = managedObjectContext.performAndWait({
            requestFactory.upstreamRequestForMessage(message, in: conversation, apiVersion: apiVersion)
        }) else {
            return .failure(MessageSendError.failedToGenerateRequest)
        }

        let response = await httpClient.send(request)

        return if response.result == .success {
            managedObjectContext.performAndWait {
                handleProteusSuccess(message: message, response: response, apiVersion: apiVersion)
            }
        } else {
            await managedObjectContext.performAndWait({
                handleProteusFailure(message: message, response: response, apiVersion: apiVersion)
            }).flatMapAsync { retry in
                if retry {
                    await sessionEstablisher.establishSession(with: missingClients(), apiVersion: apiVersion)
                        .mapError({ _ in
                            MessageSendError.failedToGenerateRequest
                        })
                        .flatMapAsync { _ in
                            await attemptToSendWithProteus(message: message, apiVersion: apiVersion)
                        }
                } else {
                    Swift.Result.failure(MessageSendError.gaveUpRetrying)
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

    private func handleProteusSuccess(message: any ProteusMessage, response: ZMTransportResponse, apiVersion: APIVersion) -> Swift.Result<Void, MessageSendError> {
        message.delivered(with: response)

        switch apiVersion {
        case .v0:
            _ = message.parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate)
        case .v1, .v2, .v3, .v4, .v5:
            if let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder) {
                processor.updateClientsChanges(
                    from: payload,
                    for: message
                )
            } else {
                WireLogger.messaging.warn("failed to get payload from response")
                return .failure(MessageSendError.failedToParseResponse)
            }
        }

        return .success(Void())
    }

    // FIXME: [jacob] return missing clients and don't rely on missedClients relationship
    private func handleProteusFailure(message: any ProteusMessage, response: ZMTransportResponse, apiVersion: APIVersion) -> Swift.Result<Bool, MessageSendError> {
        switch response.httpStatus {
        case 412:
            switch apiVersion {
            case .v0:
                return .success(message.parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate).contains(.missing))
            case .v1, .v2, .v3, .v4, .v5:
                var shouldRetry = false

                if let payload = Payload.MessageSendingStatus(response, decoder: .defaultDecoder) {
                    shouldRetry = processor.updateClientsChanges(
                        from: payload,
                        for: message
                    )
                }

                WireLogger.messaging.debug("got 412, will retry: \(shouldRetry)")
                return .success(shouldRetry)
            }

        case 533:
            guard
                let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder),
                let data = payload.data
            else {
                return .failure(MessageSendError.failedToParseResponse)
            }

            switch data.type {
            case .federation:
                payload.updateExpirationReason(for: message, with: .federationRemoteError)
            case .unknown:
                payload.updateExpirationReason(for: message, with: .unknown)
            }

            return .success(false)
        default:
            let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder)
            if payload?.label == .unknownClient {
                clientRegistrationDelegate.didDetectCurrentClientDeletion()
            }

            if case .permanentError = response.result {
                WireLogger.messaging.warn("got \(response.httpStatus), not retrying")
                return .success(false)
            } else {
                WireLogger.messaging.warn("got \(response.httpStatus), retrying")
                return .success(true)
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
