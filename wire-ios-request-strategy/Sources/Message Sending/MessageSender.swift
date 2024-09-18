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

import WireDataModel

public enum MessageSendError: Error, Equatable {
    case missingMessageProtocol
    case missingGroupID
    case missingQualifiedID
    case missingMlsService
    case unresolvedApiVersion
    case messageExpired
    case missingProteusService
}

public typealias SendableMessage = ProteusMessage & MLSMessage

// sourcery: AutoMockable
public protocol MessageSenderInterface {

    func sendMessage(message: any SendableMessage) async throws

    func broadcastMessage(message: any ProteusMessage) async throws

}

public final class MessageSender: MessageSenderInterface {

    public init (
        apiProvider: APIProviderInterface,
        clientRegistrationDelegate: ClientRegistrationDelegate,
        sessionEstablisher: SessionEstablisherInterface,
        messageDependencyResolver: MessageDependencyResolverInterface,
        quickSyncObserver: QuickSyncObserverInterface,
        context: NSManagedObjectContext
    ) {
        self.apiProvider = apiProvider
        self.clientRegistrationDelegate = clientRegistrationDelegate
        self.sessionEstablisher = sessionEstablisher
        self.messageDependencyResolver = messageDependencyResolver
        self.quickSyncObserver = quickSyncObserver
        self.context = context
        self.logAttributesBuilder = MessageLogAttributesBuilder(context: context)
    }

    private let apiProvider: APIProviderInterface
    private let context: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisherInterface
    private let messageDependencyResolver: MessageDependencyResolverInterface
    private let quickSyncObserver: QuickSyncObserverInterface
    private let proteusPayloadProcessor = MessageSendingStatusPayloadProcessor()
    private let mlsPayloadProcessor = MLSMessageSendingStatusPayloadProcessor()
    private let logAttributesBuilder: MessageLogAttributesBuilder

    public func broadcastMessage(message: any ProteusMessage) async throws {
        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug("broadcast message", attributes: logAttributes)

        await quickSyncObserver.waitForQuickSyncToFinish()

        do {
            guard let apiVersion = BackendInfo.apiVersion else { throw MessageSendError.unresolvedApiVersion }
            try await attemptToBroadcastWithProteus(message: message, apiVersion: apiVersion)
        } catch {
            let logAttributes = await logAttributesBuilder.logAttributes(message)
            WireLogger.messaging.warn("broadcast message failed: \(error)", attributes: logAttributes)
            throw error
        }
    }

    public func sendMessage(message: any SendableMessage) async throws {
        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug("send message - start wait for quick sync to finish", attributes: logAttributes)

        await quickSyncObserver.waitForQuickSyncToFinish()
        WireLogger.messaging.debug("send message - sync finished", attributes: logAttributes)

        do {
            try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
            WireLogger.messaging.debug(
                "send message - resolve dependencies finished",
                attributes: logAttributes
            )
            let timePoint = TimePoint(interval: 30, label: "attempt to send message")

            try await attemptToSend(message: message)

            WireLogger.messaging.debug(
                "send message - attemptToSend duration: \(timePoint.elapsedTime)",
                attributes: logAttributes
            )

        } catch {
            let logAttributes = await logAttributesBuilder.logAttributes(message)
            WireLogger.messaging.warn("send message - failed: \(error)", attributes: logAttributes)
            throw error
        }

        // Triggering request polling to re-evalute dependencies, other messages
        // might have been waiting for this message to be sent.
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    private func attemptToSend(message: any SendableMessage) async throws {
        let messageProtocol = await context.perform { message.conversation?.messageProtocol }

        guard let apiVersion = BackendInfo.apiVersion else { throw MessageSendError.unresolvedApiVersion }
        guard let messageProtocol else {
            throw MessageSendError.missingMessageProtocol
        }

        do {
            return switch messageProtocol {
            case .proteus, .mixed:
                try await attemptToSendWithProteus(message: message, apiVersion: apiVersion)
            case .mls:
                try await attemptToSendWithMLS(message: message, apiVersion: apiVersion)
            }
        } catch let networkError as NetworkError {
            try await context.perform { [self] in
                try handleFederationFailure(networkError: networkError, message: message)
            }
        }
    }

    private func attemptToBroadcastWithProteus(message: any ProteusMessage, apiVersion: APIVersion) async throws {

        let (proteusService, conversationID) = await context.perform { [context] in (context.proteusService, message.conversation?.qualifiedID) }

        guard let proteusService else {
            throw MessageSendError.missingProteusService
        }

        guard let conversationID else {
            throw MessageSendError.missingQualifiedID
        }

        do {
            try await message.updateUnderlyingMessageIfNeeded()

            // 1) get the info for the message from CoreData objects
            let extractor = MessageInfoExtractor(context: context)
            let messageInfo = try await extractor.infoForTransport(message: message, conversationID: conversationID)

            // 2) get the encrypted payload
            let payloadBuilder = ProteusMessagePayloadBuilder(context: context, proteusService: proteusService, useQualifiedIds: apiVersion.useQualifiedIds)
            let messageData = try await payloadBuilder.encryptForTransport(with: messageInfo)
            // 3) send it via API
            // no need to expire the broadcast message as it's only availability status no report to the user
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion).broadcastProteusMessage(message: messageData)
            await handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
        } catch let networkError as NetworkError {
            let missingClients = try await handleProteusFailure(message: message, networkError)
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await broadcastMessage(message: message)
        }
    }

    private func attemptToSendWithProteus(message: any SendableMessage, apiVersion: APIVersion) async throws {
        let (proteusService, conversationID) = await context.perform { [context] in (context.proteusService, message.conversation?.qualifiedID) }

        guard let proteusService else {
            throw MessageSendError.missingProteusService
        }

        guard let conversationID else {
            throw MessageSendError.missingQualifiedID
        }

        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug(
            "send message - via proteus",
            attributes: logAttributes
        )

        do {
            try await message.updateUnderlyingMessageIfNeeded()

            // 1) get the info for the message from CoreData objects
            let extractor = MessageInfoExtractor(context: context)
            let messageInfo = try await extractor.infoForTransport(message: message, conversationID: conversationID)

            // 2) get the encrypted payload
            let payloadBuilder = ProteusMessagePayloadBuilder(context: context, proteusService: proteusService, useQualifiedIds: apiVersion.useQualifiedIds)
            let messageData = try await payloadBuilder.encryptForTransport(with: messageInfo)
          
            
            // set expiration so request can be expired later
            await context.perform {
                if message.shouldExpire {
                    message.setExpirationDate()
                    self.context.saveOrRollback()
                }
            }

            // 3) send it via API
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion).sendProteusMessage(message: messageData, conversationID: conversationID, expirationDate: nil)
            await handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
        } catch let networkError as NetworkError {
            let missingClients = try await handleProteusFailure(message: message, networkError)
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await sendMessage(message: message)
        }
    }

    private func handleProteusSuccess(message: any ProteusMessage, messageSendingStatus: Payload.MessageSendingStatus, response: ZMTransportResponse) async {
        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug(
            "send message - via proteus succeeded",
            attributes: logAttributes
        )

        await context.perform {
            // swiftlint:disable:next todo_requires_jira_link
            message.delivered(with: response) // FIXME: jacob refactor to not use raw response
        }
        await proteusPayloadProcessor.updateClientsChanges(
            from: messageSendingStatus,
            for: message
        )
    }

    private func handleProteusFailure(message: any ProteusMessage, _ failure: NetworkError) async throws -> Set<QualifiedClientID> {
        let logAttributes = await logAttributesBuilder.logAttributes(message)

        switch failure {
        case .missingClients(let messageSendingStatus, _):
            await proteusPayloadProcessor.updateClientsChanges(
                from: messageSendingStatus,
                for: message
            )
            await context.perform {
                self.context.enqueueDelayedSave()
            }

            if await context.perform({ message.isExpired }) {
                WireLogger.messaging.warn(
                    "attempt to send with proteus failed - missing clients and message is expired",
                    attributes: logAttributes
                )

                throw MessageSendError.messageExpired
            } else {
                return Set(messageSendingStatus.missing.qualifiedClientIDs)
            }
        default:
            if case .tryAgainLater = failure.response?.result {
                if await context.perform({ message.isExpired }) {
                    WireLogger.messaging.warn(
                        "attempt to send with proteus failed - message is expired and try again later",
                        attributes: logAttributes
                    )
                    throw MessageSendError.messageExpired
                } else {
                    WireLogger.messaging.warn(
                        "attempt to send with proteus failed - try again later",
                        attributes: logAttributes
                    )
                    return Set() // FIXME: [WPB-5454] it's dangerous to retry indefinitely like this - [jacob]
                }
            } else {
                throw failure
            }
        }
    }

    private func handleFederationFailure(networkError: NetworkError, message: any SendableMessage) throws {
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
    }

    private func attemptToSendWithMLS(message: any MLSMessage, apiVersion: APIVersion) async throws {
        let (conversationID, groupID, mlsService) = await context.perform { (
            message.conversation?.qualifiedID,
            message.conversation?.mlsGroupID,
            self.context.mlsService
        ) }

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

        // set expiration so request can be expired later
        await context.perform {
            if message.shouldExpire {
                message.setExpirationDate()
                self.context.saveOrRollback()
            }
        }

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
        guard let mlsService = await context.perform({ self.context.mlsService }) else {
            throw MessageSendError.missingMlsService
        }

        return try await message.encryptForTransport { messageData in
            let encryptedData = try await mlsService.encrypt(
                message: messageData,
                for: groupID
            )
            return encryptedData
        }
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
