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
import WireFoundation

// sourcery: AutoMockable
public protocol MLSEventProcessing {

    /// Updates the conversation's `mlsStatus`
    ///
    /// - Parameters:
    ///   - conversation: The conversation to update.
    ///   - fallbackGroupID: The groupd ID of the conversation found in the event payload.
    ///   - context: The sync context.
    ///
    /// This method will update the conversation's `mlsStatus` to `.ready` if the underlying 
    /// MLS group already exists in core crypto's local storage.
    /// Otherwise, it will update it to `.pendingJoin`.

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?,
        context: NSManagedObjectContext
    ) async

    /// Processes a welcome message event.
    ///
    /// - Parameters:
    ///   - welcomeMessage: The welcome message.
    ///   - conversationID: The qualified ID of the conversation.
    ///   - context: The sync context.
    ///
    /// This method will notify the stale key material detector about the keying material update 
    /// and upload key packages if needed.
    /// It will also sync the conversation if it's missing. 
    /// And if the conversation is a one to one conversation, it will be resolved.
    ///
    /// **Note:** The welcome message itself is not being processed in this method, but rather in the ``EventDecoder``.
    /// We may want to consider removing the `welcomeMessage` parameter, as it isn't being used.

    func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext
    ) async

    /// Wipes an MLS group.
    ///
    /// - Parameters:
    ///   - conversation: The conversation for which we need to wipe the MLS group.
    ///   - context: The sync context.

    func wipeMLSGroup(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    ) async
}

/// This class provides APIs to support processing of several events where MLS is involved.
/// Such as updating the conversation's MLS status, handling welcome messages, or wiping MLS groups.

public class MLSEventProcessor: MLSEventProcessing {

    // MARK: - Properties

    private let conversationService: ConversationServiceInterface
    private let staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol

    // MARK: - Life cycle

    convenience init(context: NSManagedObjectContext) {
        self.init(
            conversationService: ConversationService(context: context),
            staleKeyMaterialDetector: StaleMLSKeyDetector(context: context)
        )
    }

    init(
        conversationService: ConversationServiceInterface,
        staleKeyMaterialDetector: StaleMLSKeyDetectorProtocol
    ) {
        self.conversationService = conversationService
        self.staleKeyMaterialDetector = staleKeyMaterialDetector
    }

    // MARK: - Update conversation

    public func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?,
        context: NSManagedObjectContext
    ) async {
        WireLogger.mls.debug("MLS event processor updating conversation if needed")

        let (messageProtocol, mlsGroupID, mlsService) = await context.perform {
            (
                conversation.messageProtocol,
                conversation.mlsGroupID,
                context.mlsService
            )
        }

        guard messageProtocol.isOne(of: .mls, .mixed) else {
            return logWarn(aborting: .conversationUpdate, withReason: .conversationNotMLSCapable)
        }

        guard let mlsGroupID = mlsGroupID ?? fallbackGroupID else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingGroupID)
        }
        await context.perform {
            if conversation.mlsGroupID == nil {
                conversation.mlsGroupID = mlsGroupID
                WireLogger.mls.info("MLS event processor set the group ID to value: (\(mlsGroupID.safeForLoggingDescription)) for conversation: (\(String(describing: conversation.qualifiedID))")
            }
        }

        guard let mlsService else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingMLSService)
        }

        let conversationExists: Bool
        do {
            conversationExists = try await mlsService.conversationExists(groupID: mlsGroupID)
        } catch {
            WireLogger.mls.error("failed to check if conversation \(mlsGroupID.safeForLoggingDescription) exists: \(error)")
            conversationExists = false
        }
        let newStatus: MLSGroupStatus = conversationExists ? .ready : .pendingJoin

        await context.perform {
            let previousStatus = conversation.mlsStatus

            conversation.mlsStatus = newStatus
            context.saveOrRollback()
            Flow.createGroup.checkpoint(description: "saved ZMConversation for MLS")

            if newStatus != previousStatus {
                WireLogger.mls.debug("conversation \(String(describing: conversation.qualifiedID)) status changed: \(String(describing: previousStatus)) -> \(newStatus))")
            }
        }
    }

    // MARK: - Process welcome message

    public func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext
    ) async {
        guard let mlsService = await context.perform({ context.mlsService }) else {
            return logWarn(aborting: .processingWelcome, withReason: .missingMLSService)
        }
        let migrator = OneOnOneMigrator(mlsService: mlsService)

        await process(
            welcomeMessage: welcomeMessage,
            conversationID: conversationID,
            in: context,
            mlsService: mlsService,
            oneOnOneResolver: OneOnOneResolver(migrator: migrator)
        )
    }

    func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        oneOnOneResolver: OneOnOneResolverInterface
    ) async {
        WireLogger.mls.info("MLS event processor is processing welcome message")

        guard let (conversation, groupID) = await context.perform({
            let conversation = ZMConversation.fetch(with: conversationID, in: context)
            return (conversation, conversation?.mlsGroupID) as? (ZMConversation, MLSGroupID)
        }) else { return }

        staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)
        await mlsService.uploadKeyPackagesIfNeeded()
        await conversationService.syncConversationIfMissing(qualifiedID: conversationID)

        await resolveOneOnOneConversationIfNeeded(
            conversation: conversation,
            in: context,
            oneOneOneResolver: oneOnOneResolver
        )
    }

    private func resolveOneOnOneConversationIfNeeded(
        conversation: ZMConversation,
        in context: NSManagedObjectContext,
        oneOneOneResolver: OneOnOneResolverInterface
    ) async {
        WireLogger.mls.debug("resolving one on one conversation")

        let userID: QualifiedID? = await context.perform {
            guard conversation.conversationType == .oneOnOne else {
                WireLogger.mls.info("conversation type is not expected 'oneOnOne', aborting.")
                return nil
            }

            guard
                let otherUser = conversation.localParticipantsExcludingSelf.first,
                let otherUserID = otherUser.remoteIdentifier,
                let otherUserDomain = otherUser.domain ?? BackendInfo.domain
            else {
                WireLogger.mls.warn("failed to resolve one on one conversation: can not get other user id")
                return nil
            }

            return QualifiedID(
                uuid: otherUserID,
                domain: otherUserDomain
            )
        }

        guard let userID else { return }

        do {
            try await oneOneOneResolver.resolveOneOnOneConversation(with: userID, in: context)

            await context.perform {
                _ = context.saveOrRollback()
            }

            WireLogger.mls.debug("successfully resolved one on one conversation")
        } catch {
            WireLogger.mls.warn("failed to resolve one on one conversation: \(error)")
        }
    }

    // MARK: - Wipe conversation

    public func wipeMLSGroup(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    ) async {
        WireLogger.mls.info("MLS event processor is wiping conversation")

        let (messageProtocol, groupID, mlsService) = await context.perform {
            return (
                conversation.messageProtocol,
                conversation.mlsGroupID,
                context.mlsService
            )
        }

        guard messageProtocol.isOne(of: .mls, .mixed) else {
            return logWarn(aborting: .conversationWipe, withReason: .conversationNotMLSCapable)
        }

        guard let groupID else {
            return logWarn(aborting: .conversationWipe, withReason: .missingGroupID)
        }

        guard let mlsService else {
            return logWarn(aborting: .conversationWipe, withReason: .missingMLSService)
        }

        do {
            try await mlsService.wipeGroup(groupID)
        } catch {
            WireLogger.mls.error("mlsService.wipeGroup(\(groupID.safeForLoggingDescription)) threw error: \(String(reflecting: error))")
        }
    }

    // MARK: Log Helpers

    private func logWarn(
        aborting action: ActionLog,
        withReason reason: AbortReason
    ) {
        WireLogger.mls.warn("MLS event processor aborting \(action.rawValue): \(reason.stringValue)")
    }

    private enum ActionLog: String {
        case conversationUpdate = "conversation update"
        case conversationWipe = "conversation wipe"
        case joiningGroup = "joining group"
        case processingWelcome = "processing welcome message"
    }

    private enum AbortReason {
        case conversationNotMLSCapable
        case missingGroupID
        case missingMLSService
        case other(reason: String)

        var stringValue: String {
            switch self {
            case .conversationNotMLSCapable:
                return "conversation is not MLS capable"
            case .missingGroupID:
                return "missing group ID"
            case .missingMLSService:
                return "missing mlsService"
            case .other(reason: let reason):
                return reason
            }
        }
    }
}
