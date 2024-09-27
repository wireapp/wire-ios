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

// MARK: - MessageSendError

public enum MessageSendError: Error, Equatable {
    case missingMessageProtocol
    case missingGroupID
    case missingQualifiedID
    case missingMlsService
    case unresolvedApiVersion
    case messageExpired
}

public typealias SendableMessage = MLSMessage & ProteusMessage

// MARK: - MessageSenderInterface

// sourcery: AutoMockable
public protocol MessageSenderInterface {
    func sendMessage(message: any SendableMessage) async throws

    func broadcastMessage(message: any ProteusMessage) async throws
}

// MARK: - MessageSender

public final class MessageSender: MessageSenderInterface {
    // MARK: Lifecycle

    public init(
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

    // MARK: Public

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

            try await attemptToSend(message: message)
        } catch {
            let logAttributes = await logAttributesBuilder.logAttributes(message)
            WireLogger.messaging.warn("send message - failed: \(error)", attributes: logAttributes)
            throw error
        }

        // Triggering request polling to re-evalute dependencies, other messages
        // might have been waiting for this message to be sent.
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    // MARK: Private

    private let apiProvider: APIProviderInterface
    private let context: NSManagedObjectContext
    private let clientRegistrationDelegate: ClientRegistrationDelegate
    private let sessionEstablisher: SessionEstablisherInterface
    private let messageDependencyResolver: MessageDependencyResolverInterface
    private let quickSyncObserver: QuickSyncObserverInterface
    private let proteusPayloadProcessor = MessageSendingStatusPayloadProcessor()
    private let mlsPayloadProcessor = MLSMessageSendingStatusPayloadProcessor()
    private let logAttributesBuilder: MessageLogAttributesBuilder

    private func attemptToSend(message: any SendableMessage) async throws {
        let messageProtocol = await context.perform { message.conversation?.messageProtocol }

        guard let apiVersion = BackendInfo.apiVersion else { throw MessageSendError.unresolvedApiVersion }
        guard let messageProtocol else {
            throw MessageSendError.missingMessageProtocol
        }

        await context.perform {
            if message.shouldExpire {
                message.setExpirationDate()
                self.context.saveOrRollback()
            }
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
        do {
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
                .broadcastProteusMessage(message: message)
            await handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
        } catch let networkError as NetworkError {
            let missingClients = try await handleProteusFailure(message: message, networkError)
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await broadcastMessage(message: message)
        }
    }

    private func attemptToSendWithProteus(message: any SendableMessage, apiVersion: APIVersion) async throws {
        let conversationID = await context.perform { message.conversation?.qualifiedID }

        guard let conversationID else {
            throw MessageSendError.missingQualifiedID
        }

        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug(
            "send message - via proteus",
            attributes: logAttributes
        )

        do {
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion).sendProteusMessage(
                message: message,
                conversationID: conversationID
            )
            await handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
        } catch let networkError as NetworkError {
            let missingClients = try await handleProteusFailure(message: message, networkError)
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await sendMessage(message: message)
        }
    }

    private func handleProteusSuccess(
        message: any ProteusMessage,
        messageSendingStatus: Payload.MessageSendingStatus,
        response: ZMTransportResponse
    ) async {
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

    private func handleProteusFailure(
        message: any ProteusMessage,
        _ failure: NetworkError
    ) async throws -> Set<QualifiedClientID> {
        let logAttributes = await logAttributesBuilder.logAttributes(message)

        switch failure {
        case let .missingClients(messageSendingStatus, _):
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
        if case let .invalidRequestError(responseFailure, _) = networkError, responseFailure.code == 533 {
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
        let (payload, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
            .sendMLSMessage(
                message: encryptedData,
                conversationID: conversationID,
                expirationDate: context.perform { message.expirationDate }
            )

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

extension Payload.ClientListByQualifiedUserID {
    fileprivate var qualifiedClientIDs: [QualifiedClientID] {
        var qualifiedClientIDs: [QualifiedClientID] = []
        for (domain, clientListByUserID) in self {
            for (userID, clientIDs) in clientListByUserID {
                if let userUuid = UUID(uuidString: userID) {
                    qualifiedClientIDs.append(
                        contentsOf: clientIDs.map { clientID in
                            QualifiedClientID(
                                userID: userUuid,
                                domain: domain,
                                clientID: clientID
                            )
                        }
                    )
                }
            }
        }
        return qualifiedClientIDs
    }
}
