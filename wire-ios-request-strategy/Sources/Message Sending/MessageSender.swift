//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import GenericMessageProtocol
import WireCoreCrypto
import WireDataModel
import WireLogging
import WireTransport
import WireUtilitiesPackage

public enum MessageSendError: Error {
    case missingMessageProtocol
    case missingGroupID
    case missingQualifiedID
    case missingMlsService
    case unresolvedApiVersion
    case messageExpired
    case missingProteusService
    case failed(Error)
    case outboxWaitingForConnection
    case outboxConversationUnavailable
}

public typealias SendableMessage = MLSMessage & ProteusMessage

// sourcery: AutoMockable
public protocol MessageSenderInterface {

    func sendMessage(message: any SendableMessage) async throws

    func broadcastMessage(message: any ProteusMessage) async throws

}

// sourcery: AutoMockable
public protocol InitiateResetMLSConversationUseCaseProtocol {
    func invoke(groupID: MLSGroupID, epoch: UInt64) async
}

public final class MessageSender: MessageSenderInterface {

    public init(
        apiProvider: APIProviderInterface,
        sessionEstablisher: SessionEstablisherInterface,
        messageDependencyResolver: MessageDependencyResolverInterface,
        context: NSManagedObjectContext,
        incrementalSyncObserver: IncrementalSyncObserverProtocol,
        initiateResetMLSConversationUseCase: InitiateResetMLSConversationUseCaseProtocol,
        featureRepository: LegacyFeatureRepositoryInterface,
        apiVersion: WireTransport.APIVersion?,
        backgroundTaskExecuter: any BackgroundTaskExecuter,
        reachability: ReachabilityProvider? = nil
    ) {
        self.apiProvider = apiProvider
        self.sessionEstablisher = sessionEstablisher
        self.messageDependencyResolver = messageDependencyResolver
        self.context = context
        self.logAttributesBuilder = MessageLogAttributesBuilder(context: context)
        self.incrementalSyncObserver = incrementalSyncObserver
        self.initiateResetMLSConversationUseCase = initiateResetMLSConversationUseCase
        self.featureRepository = featureRepository
        self.apiVersion = apiVersion
        self.backgroundTaskExecuter = backgroundTaskExecuter
        self.reachability = reachability
    }

    private let featureRepository: LegacyFeatureRepositoryInterface
    private let initiateResetMLSConversationUseCase: InitiateResetMLSConversationUseCaseProtocol
    private let incrementalSyncObserver: IncrementalSyncObserverProtocol
    private let apiProvider: APIProviderInterface
    private let context: NSManagedObjectContext
    private let sessionEstablisher: SessionEstablisherInterface
    private let messageDependencyResolver: MessageDependencyResolverInterface
    private let proteusPayloadProcessor = MessageSendingStatusPayloadProcessor()
    private let mlsPayloadProcessor = MLSMessageSendingStatusPayloadProcessor()
    private let logAttributesBuilder: MessageLogAttributesBuilder
    private let maxRetryAttempts = 3
    private var retryCount = 0
    private let apiVersion: WireTransport.APIVersion?
    private let backgroundTaskExecuter: any BackgroundTaskExecuter
    private let reachability: ReachabilityProvider?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        try await withBackgroundTask(name: "broadcast Message", executer: backgroundTaskExecuter) { [self] in
            let logAttributes = await logAttributesBuilder.logAttributes(message)
            WireLogger.messaging.debug("broadcast message", attributes: logAttributes)

            await incrementalSyncObserver.waitUntilCanSendMessage()

            do {
                guard let apiVersion else { throw MessageSendError.unresolvedApiVersion }
                try await attemptToBroadcastWithProteus(message: message, apiVersion: apiVersion)
            } catch {
                let logAttributes = await logAttributesBuilder.logAttributes(message)
                WireLogger.messaging.warn("broadcast message failed: \(error)", attributes: logAttributes)
                throw error
            }
        }
    }

    public func sendMessage(message: any SendableMessage) async throws {
        let usesOutbox = await context.perform {
            (message as? ZMMessage).map { $0.outboxState != .notEnrolled } ?? false
        }
        if usesOutbox {
            try await sendOutboxMessage(message)
            return
        }
        try await withBackgroundTask(name: "send Message", executer: backgroundTaskExecuter) { [self] in
            let logAttributes = await logAttributesBuilder.logAttributes(message)
            WireLogger.messaging.debug("send message - start wait for quick sync to finish", attributes: logAttributes)

            await incrementalSyncObserver.waitUntilCanSendMessage()

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
    }

    private func attemptToSend(
        message: any SendableMessage,
        outboxAttempt: MessageOutboxAttempt? = nil
    ) async throws {
        let messageProtocol = await context.perform { message.conversation?.messageProtocol }

        guard let apiVersion else { throw MessageSendError.unresolvedApiVersion }
        guard let messageProtocol else {
            throw MessageSendError.missingMessageProtocol
        }

        do {
            switch messageProtocol {
            case .proteus, .mixed:
                try await attemptToSendWithProteus(message: message, apiVersion: apiVersion, outboxAttempt: outboxAttempt)
            case .mls:
                try await attemptToSendWithMLS(message: message, apiVersion: apiVersion, outboxAttempt: outboxAttempt)
            }

            // Success! Reset count
            if outboxAttempt == nil { retryCount = 0 }

        } catch let networkError as NetworkError {
            if outboxAttempt != nil { throw networkError }
            try await context.perform { [self] in
                try handleFederationFailure(networkError: networkError, message: message)
            }
        }
    }

    private func attemptToBroadcastWithProteus(message: any ProteusMessage, apiVersion: APIVersion) async throws {

        let proteusService = await context.perform { [context] in
            context.proteusService
        }

        guard let proteusService else {
            throw MessageSendError.missingProteusService
        }

        do {
            try await message.prepareMessageForSending()

            // 1) get the info for the message from CoreData objects
            let extractor = MessageInfoExtractor(context: context)
            let messageInfo = try await extractor.infoForBroadcast(message: message)

            // 2) get the encrypted payload
            let payloadBuilder = ProteusMessagePayloadBuilder(
                proteusService: proteusService,
                useQualifiedIds: apiVersion.useQualifiedIds
            )
            let messageData = try await payloadBuilder.encryptForTransport(with: messageInfo)

            // 3) send it via API
            // no need to expire the broadcast message as it's only availability status no report to the user
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
                .broadcastProteusMessage(message: messageData)
            await handleProteusSuccess(message: message, messageSendingStatus: messageStatus, response: response)
        } catch let networkError as NetworkError {
            let operation: () async throws -> Void = { [weak self] in
                try await self?.broadcastMessage(message: message)
            }

            try await handleNetworkError(
                networkError,
                message: message,
                apiVersion: apiVersion,
                operation: operation
            )
        }
    }

    private func attemptToSendWithProteus(
        message: any SendableMessage,
        apiVersion: APIVersion,
        outboxAttempt: MessageOutboxAttempt? = nil
    ) async throws {
        let (proteusService, conversationID) = await context.perform { [context] in (
            context.proteusService,
            message.conversation?.qualifiedID
        ) }

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
            try await message.prepareMessageForSending()

            // 1) get the info for the message from CoreData objects
            let extractor = MessageInfoExtractor(context: context)
            var messageInfo = try await extractor.infoForSending(message: message, conversationID: conversationID)
            if let outboxAttempt {
                messageInfo.genericMessage = try await outboxContent(outboxAttempt, message: message)
            }

            // 2) get the encrypted payload
            let payloadBuilder = ProteusMessagePayloadBuilder(
                proteusService: proteusService,
                useQualifiedIds: apiVersion.useQualifiedIds
            )
            let messageData = try await payloadBuilder.encryptForTransport(with: messageInfo)

            // set expiration so request can be expired later
            if outboxAttempt != nil { try Task.checkCancellation() }
            let expirationDate = try await context.perform {
                if let outboxAttempt {
                    return try self.prepareOutboxHandoff(outboxAttempt, message: message)
                }
                if message.shouldExpire {
                    message.setExpirationDate()
                    self.context.saveOrRollback()
                    return message.expirationDate
                }
                return nil
            }

            // 3) send it via API
            let (messageStatus, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
                .sendProteusMessage(
                    message: messageData,
                    conversationID: conversationID,
                    expirationDate: expirationDate
                )
            await handleProteusSuccess(
                message: message,
                messageSendingStatus: messageStatus,
                response: response,
                outboxAttempt: outboxAttempt
            )
        } catch let networkError as NetworkError {
            if outboxAttempt != nil { throw networkError }
            let operation: () async throws -> Void = { [weak self] in
                try await self?.sendMessage(message: message)
            }

            try await handleNetworkError(
                networkError,
                message: message,
                apiVersion: apiVersion,
                operation: operation
            )
        }
    }

    private func handleNetworkError(
        _ networkError: NetworkError,
        message: any ProteusMessage,
        apiVersion: APIVersion,
        operation: () async throws -> Void
    ) async throws {
        do {
            let missingClients = try await handleProteusFailure(message: message, networkError)
            try await sessionEstablisher.establishSession(with: missingClients, apiVersion: apiVersion)
            try await operation()
        } catch let error as MessageSendError {
            guard retryCount < maxRetryAttempts else {
                retryCount = 0
                throw error
            }

            retryCount += 1

            try await operation()
        } catch {
            throw error
        }
    }

    private func handleProteusSuccess(
        message: any ProteusMessage,
        messageSendingStatus: Payload.MessageSendingStatus,
        response: ZMTransportResponse,
        outboxAttempt: MessageOutboxAttempt? = nil
    ) async {
        let logAttributes = await logAttributesBuilder.logAttributes(message)
        WireLogger.messaging.debug(
            "send message - via proteus succeeded",
            attributes: logAttributes
        )

        let appliesToCurrentMessage = await context.perform { () -> Bool in
            if let outboxAttempt {
                guard let row = message as? ZMMessage,
                      self.isCurrentOutboxAttempt(outboxAttempt.identifier, row: row)
                else { return false }
            }
            // swiftlint:disable:next todo_requires_jira_link
            message.delivered(with: response) // FIXME: jacob refactor to not use raw response
            return true
        }
        guard appliesToCurrentMessage else { return }
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

                    throw MessageSendError.failed(failure)
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
                responseFailure.updateExpirationReason(for: message, with: .other)
            case .none:
                break
            }
        }
        throw networkError
    }

    private func attemptToSendWithMLS(
        message: any SendableMessage,
        apiVersion: APIVersion,
        outboxAttempt: MessageOutboxAttempt? = nil
    ) async throws {
        let (conversationID, groupID, mlsService, mlsStatus) = await context.perform { (
            message.conversation?.qualifiedID,
            message.conversation?.mlsGroupID,
            self.context.mlsService,
            message.conversation?.mlsStatus
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

        do {
            let conversationExists = try await mlsService.conversationExists(groupID: groupID)
            let isUnestablishedGroup: Bool = if conversationExists {
                try await mlsService.epoch(for: groupID) == 0
            } else {
                false
            }

            if isUnestablishedGroup, conversationID.domain == mlsService.localDomain {
                try await mlsService.wipeGroup(groupID)
                try await mlsService.reEstablishPendingGroup(groupID: groupID)
            } else if mlsStatus?.isOne(of: .pendingJoinAfterReset, .pendingJoin) == true,
                      conversationID.domain == mlsService.localDomain {
                try await mlsService.reEstablishPendingGroup(groupID: groupID)
            }

            try await mlsService.commitPendingProposals(in: groupID, skipRetry: true)
            let encryptedData: Data
            if let outboxAttempt {
                let content = try await outboxContent(outboxAttempt, message: message)
                encryptedData = try await mlsService.encrypt(message: content.serializedData(), for: groupID)
            } else {
                encryptedData = try await encryptMlsMessage(message, groupID: groupID)
            }

            // set expiration so request can be expired later
            if outboxAttempt != nil { try Task.checkCancellation() }
            try await context.perform {
                if let outboxAttempt {
                    _ = try self.prepareOutboxHandoff(outboxAttempt, message: message)
                    return
                }
                if message.shouldExpire {
                    message.setExpirationDate()
                    self.context.saveOrRollback()
                }
            }

            let (payload, response) = try await apiProvider.messageAPI(apiVersion: apiVersion)
                .sendMLSMessage(
                    message: encryptedData,
                    conversationID: conversationID,
                    expirationDate: await context.perform { message.expirationDate }
                )

            try await context.perform {
                if let outboxAttempt {
                    guard let row = message as? ZMMessage,
                          self.isCurrentOutboxAttempt(outboxAttempt.identifier, row: row)
                    else { throw MessageOutboxError.staleAttempt }
                }
                // handle 201 case failed_to_send
                // https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/556564601/Use+case+sending+a+message+MLS
                self.mlsPayloadProcessor.updateFailedRecipients(from: payload, for: message)
                message.delivered(with: response)
            }
        } catch let error as SendMLSMessageFailure {
            if outboxAttempt != nil { throw error }
            try await handleSendMLSMessageFailure(error, message: message, groupID: groupID, mlsService: mlsService)
        } catch let CoreCryptoError.Mls(.MessageRejected(reason: reason)) {

            if let supportedError = SendMLSMessageFailure(from: reason) {
                if outboxAttempt != nil { throw supportedError }
                try await handleSendMLSMessageFailure(
                    supportedError,
                    message: message,
                    groupID: groupID,
                    mlsService: mlsService
                )
            } else {
                throw CoreCryptoError.Mls(mlsError: .MessageRejected(reason: reason))
            }

        }
    }

    private func handleSendMLSMessageFailure(
        _ error: SendMLSMessageFailure,
        message: any SendableMessage,
        groupID: MLSGroupID,
        mlsService: MLSServiceInterface
    ) async throws {
        switch error {
        case .mlsStaleMessage:
            // We should try to repair the conversation for the `mlsStaleMessage` error.
            // This error indicates that the message was not encrypted in the latest epoch.
            let operation: () async throws -> Void = { [weak self] in
                try await self?.sendMessage(message: message)
            }

            try await handleMLSStaleMessageError(
                groupID: groupID,
                mlsService: mlsService,
                operation: operation
            )
        case .mlsInvalidLeafNodeIndex, .mlsInvalidLeafNodeSignature:
            let feature = await featureRepository.fetchAllowedGlobalOperations()
            guard feature.status == .enabled,
                  feature.config.mlsConversationReset == true
            else {
                WireLogger.messaging.debug(
                    "No need to initiate reset broken MLS conversation, FF is OFF"
                )
                throw error
            }

            let epoch = await context.perform { message.conversation?.epoch }

            await initiateResetMLSConversationUseCase
                .invoke(
                    groupID: groupID,
                    epoch: epoch ?? 0
                )
        case let .groupOutOfSync(missingUsers):
            guard retryCount < maxRetryAttempts else {
                retryCount = 0
                throw error
            }

            retryCount += 1

            let users = missingUsers.map { MLSUser($0) }
            try await mlsService.addMembersToConversation(with: users, for: groupID)
            try await sendMessage(message: message)
        case .mlsCommitMissingReferences, .mlsClientMismatch:
            // here a simple retry is used but as an optim we could use a backoff
            guard retryCount < maxRetryAttempts else {
                retryCount = 0
                throw error
            }

            retryCount += 1

            try await sendMessage(message: message)
        default:
            throw error
        }
    }

    private func handleMLSStaleMessageError(
        groupID: MLSGroupID,
        mlsService: MLSServiceInterface,
        operation: () async throws -> Void
    ) async throws {
        do {
            await mlsService.fetchAndRepairGroup(with: groupID)
            try await operation()
        } catch let error as MessageSendError {
            guard retryCount < maxRetryAttempts else {
                retryCount = 0
                throw error
            }

            retryCount += 1

            try await operation()
        }
    }

    private func encryptMlsMessage(_ message: any MLSMessage, groupID: MLSGroupID) async throws -> Data {
        guard let mlsService = await context.perform({ self.context.mlsService }) else {
            throw MessageSendError.missingMlsService
        }

        return try await message.encryptForTransport { messageData in
            try await mlsService.encrypt(
                message: messageData,
                for: groupID
            )
        }
    }
}

private extension MessageSender {

    func sendOutboxMessage(_ message: any SendableMessage) async throws {
        guard let row = message as? ZMMessage else { throw MessageOutboxError.invalidTransition }
        guard reachability?.mayBeReachable != false else { throw MessageSendError.outboxWaitingForConnection }

        await incrementalSyncObserver.waitUntilCanSendMessage()
        try Task.checkCancellation()
        try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        try Task.checkCancellation()

        try await withBackgroundTask(name: "send queued message", executer: backgroundTaskExecuter) { [self] in
            for retry in 0...maxRetryAttempts {
                try Task.checkCancellation()
                let attempt = try await context.perform {
                    guard self.reachability?.mayBeReachable != false else {
                        throw MessageSendError.outboxWaitingForConnection
                    }
                    guard let content = message.underlyingMessage else { throw MessageOutboxError.invalidPayload }
                    let attempt = try row.prepareOutboxAttempt(payload: content.serializedData())
                    do {
                        try self.context.save()
                    } catch {
                        try? row.rescheduleOutboxAttempt(attempt.identifier)
                        throw error
                    }
                    return attempt
                }

                do {
                    try await attemptToSend(message: message, outboxAttempt: attempt)
                    try await finishOutboxAttempt(attempt, message: message)
                    RequestAvailableNotification.notifyNewRequestsAvailable(nil)
                    return
                } catch {
                    if let networkError = error as? NetworkError,
                       let response = networkError.response, response.result == .success {
                        // Server acceptance is known even if its recipient-status payload could not be decoded.
                        WireLogger.messaging.warn("outbox send accepted with unreadable recipient status")
                        try await finishOutboxAttempt(attempt, message: message, response: response)
                        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
                        return
                    }

                    let notSubmitted = (error as? NetworkError)?.response?.transportSessionError?
                        .userInfo[ZMTransportSessionRequestNotSubmittedKey] as? Bool == true
                    let canRepair = retry < maxRetryAttempts && isRepairableOutboxRejection(error)
                    try await context.perform {
                        guard self.isCurrentOutboxAttempt(attempt.identifier, row: row) else {
                            throw MessageOutboxError.staleAttempt
                        }
                        if notSubmitted || canRepair || row.outboxState == .preparing {
                            let retryDate = notSubmitted
                                ? Date(timeIntervalSinceNow: TimeInterval(min(30, max(1, row.outboxAttemptCount))))
                                : nil
                            try row.rescheduleOutboxAttempt(attempt.identifier, notBefore: retryDate)
                            row.expirationDate = nil
                        } else if self.isDefiniteOutboxRejection(error) {
                            try row.failOutboxAttempt(attempt.identifier)
                        } else {
                            try row.markOutboxAttemptUncertain(attempt.identifier)
                        }
                        try self.context.save()
                    }
                    if notSubmitted { throw MessageSendError.outboxWaitingForConnection }
                    if canRepair {
                        try await repairOutboxRejection(error, message: message)
                        continue
                    }
                    await resetOutboxConversationIfNeeded(error, message: message)
                    throw error
                }
            }
        }
    }

    func outboxContent(_ attempt: MessageOutboxAttempt, message: any SendableMessage) async throws -> GenericMessage {
        try await context.perform {
            guard let row = message as? ZMMessage,
                  self.isCurrentOutboxAttempt(attempt.identifier, row: row)
            else { throw MessageOutboxError.staleAttempt }
            var content = try GenericMessage(serializedData: attempt.payload)
            if message.conversation?.conversationType == .oneOnOne {
                content.setExpectsReadConfirmation(ZMUser.selfUser(in: self.context).readReceiptsEnabled)
            }
            if let legalHoldStatus = message.conversation?.legalHoldStatus {
                content.setLegalHoldStatus(legalHoldStatus.denotesEnabledComplianceDevice ? .enabled : .disabled)
            }
            return content
        }
    }

    /// Called on the context queue after encryption, immediately before HTTP handoff.
    func prepareOutboxHandoff(_ attempt: MessageOutboxAttempt, message: any SendableMessage) throws -> Date? {
        guard reachability?.mayBeReachable != false else { throw MessageSendError.outboxWaitingForConnection }
        guard let row = message as? ZMMessage else { throw MessageOutboxError.invalidTransition }
        guard let conversation = message.conversation, conversation.isSelfAnActiveMember else {
            throw MessageSendError.outboxConversationUnavailable
        }
        if conversation.isDegraded, !message.shouldIgnoreTheSecurityLevelCheck {
            throw MessageDependencyResolverError.securityLevelDegraded
        }
        if conversation.legalHoldStatus == .pendingApproval {
            throw MessageDependencyResolverError.legalHoldPendingApproval
        }
        try row.markOutboxAttemptSending(attempt)
        if message.shouldExpire { message.setExpirationDate() }
        do {
            try context.save()
        } catch {
            // No request was submitted. Keep the live context from looking like an in-flight send.
            try? row.rescheduleOutboxAttempt(attempt.identifier)
            row.expirationDate = nil
            throw error
        }
        return message.expirationDate
    }

    func finishOutboxAttempt(
        _ attempt: MessageOutboxAttempt,
        message: any SendableMessage,
        response: ZMTransportResponse? = nil
    ) async throws {
        try await context.perform {
            guard let row = message as? ZMMessage,
                  self.isCurrentOutboxAttempt(attempt.identifier, row: row)
            else { throw MessageOutboxError.staleAttempt }
            let clientMessage = row as? ZMClientMessage
            let claimedContent = try GenericMessage(serializedData: attempt.payload)
            let needsPreviewUpdate = clientMessage?.linkPreviewState == .uploaded
                && clientMessage?.underlyingMessage?.linkPreviews != claimedContent.linkPreviews
            if let response { message.delivered(with: response) }
            row.markAsSent()
            try row.completeOutboxAttempt(attempt.identifier)
            row.expirationDate = nil
            if needsPreviewUpdate {
                try row.enqueueInOutbox(operation: .contentUpdate)
                row.delivered = false
            }
            try self.context.save()
        }
    }

    func isCurrentOutboxAttempt(_ identifier: UUID, row: ZMMessage) -> Bool {
        guard let state = row.outboxState else { return false }
        return !row.isDeleted && !row.hasBeenDeleted && !row.isObfuscated && row.outboxAttemptIdentifier == identifier
            && [.preparing, .sending, .uncertain].contains(state)
    }

    func isRepairableOutboxRejection(_ error: Error) -> Bool {
        if let error = error as? NetworkError, case .missingClients = error { return true }
        guard let error = error as? SendMLSMessageFailure else { return false }
        switch error {
        case .mlsStaleMessage, .mlsClientMismatch, .mlsCommitMissingReferences, .groupOutOfSync:
            return true
        default:
            return false
        }
    }

    func isDefiniteOutboxRejection(_ error: Error) -> Bool {
        if let networkError = error as? NetworkError, let response = networkError.response {
            return response.httpStatus == 400 || response.httpStatus == 403 || response.httpStatus == 404
                || response.httpStatus == 412
        }
        guard let error = error as? SendMLSMessageFailure else { return false }
        switch error {
        case .malformedResponse, .unreachableDomains, .nonFederatingDomains, .unknown:
            return false
        default:
            return true
        }
    }

    func repairOutboxRejection(_ error: Error, message: any SendableMessage) async throws {
        if let error = error as? NetworkError, let apiVersion {
            let clients = try await handleProteusFailure(message: message, error)
            try await sessionEstablisher.establishSession(with: clients, apiVersion: apiVersion)
            return
        }
        guard let error = error as? SendMLSMessageFailure,
              let (service, groupID) = await context.perform({ () -> (MLSServiceInterface, MLSGroupID)? in
                  guard let service = self.context.mlsService,
                        let groupID = message.conversation?.mlsGroupID else { return nil }
                  return (service, groupID)
              })
        else { throw error }
        switch error {
        case .mlsStaleMessage:
            await service.fetchAndRepairGroup(with: groupID)
        case let .groupOutOfSync(users):
            try await service.addMembersToConversation(with: users.map { MLSUser($0) }, for: groupID)
        default:
            break
        }
    }

    func resetOutboxConversationIfNeeded(_ error: Error, message: any SendableMessage) async {
        guard let error = error as? SendMLSMessageFailure else { return }
        switch error {
        case .mlsInvalidLeafNodeIndex, .mlsInvalidLeafNodeSignature:
            let feature = await featureRepository.fetchAllowedGlobalOperations()
            guard feature.status == .enabled, feature.config.mlsConversationReset == true else { return }
            let (groupID, epoch) = await context.perform {
                (message.conversation?.mlsGroupID, message.conversation?.epoch ?? 0)
            }
            if let groupID {
                await initiateResetMLSConversationUseCase.invoke(groupID: groupID, epoch: epoch)
            }
        default:
            break
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

private extension SendMLSMessageFailure {

    init?(from reason: String) {
        guard let error = try? JSONDecoder().decode(
            MLSTransportError.self,
            from: Data(reason.utf8)
        ) else {
            return nil
        }

        switch error {
        case .mlsClientMismatch:
            self = .mlsClientMismatch
        case .mlsCommitMissingReferences:
            self = .mlsCommitMissingReferences(message: "")
        case .mlsStaleMessage:
            self = .mlsStaleMessage
        case .mlsInvalidLeafNodeIndex:
            self = .mlsInvalidLeafNodeIndex(message: "")
        case .mlsInvalidLeafNodeSignature:
            self = .mlsInvalidLeafNodeSignature(message: "")
        case let .groupOutOfSync(missingUsers):
            self = .groupOutOfSync(missingUsers: missingUsers)
        default:
            return nil
        }
    }
}
