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

// sourcery: AutoMockable
public protocol MLSEventProcessing {

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?,
        context: NSManagedObjectContext
    ) async

    func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext
    ) async

    func wipeMLSGroup(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    ) async
}

public class MLSEventProcessor: MLSEventProcessing {

    // MARK: - Properties

    private let conversationService: ConversationServiceInterface

    // MARK: - Life cycle

    convenience init(context: NSManagedObjectContext) {
        self.init(conversationService: ConversationService(context: context))
    }

    init(conversationService: ConversationServiceInterface) {
        self.conversationService = conversationService
    }

    // MARK: - Update conversation

    public func updateConversationIfNeeded(
        conversation: ZMConversation,
        fallbackGroupID: MLSGroupID?,
        context: NSManagedObjectContext
    ) async {
        WireLogger.mls.debug("MLS event processor updating conversation if needed")

        let (messageProtocol, mlsGroupID, mlsService) = await context.perform {
            return (
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

        let conversationExists = await mlsService.conversationExists(groupID: mlsGroupID)
        let previousStatus = await context.perform { conversation.mlsStatus }
        let newStatus = conversationExists ? MLSGroupStatus.ready : .pendingJoin

        await context.perform {
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
        WireLogger.mls.info("MLS event processor is processing welcome message")

        guard let mlsService = await context.perform({ context.mlsService }) else {
            return logWarn(aborting: .processingWelcome, withReason: .missingMLSService)
        }

        let oneOnOneResolver = OneOnOneResolver(
            protocolSelector: OneOnOneProtocolSelector(),
            migrator: OneOnOneMigrator(mlsService: mlsService)
        )

        await process(
            welcomeMessage: welcomeMessage,
            conversationID: conversationID,
            in: context,
            mlsService: mlsService,
            oneOnOneResolver: oneOnOneResolver
        )
    }

    func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        oneOnOneResolver: OneOnOneResolverInterface
    ) async {
        do {
            let groupID = try await mlsService.processWelcomeMessage(welcomeMessage: welcomeMessage)
            await mlsService.uploadKeyPackagesIfNeeded()
            await conversationService.syncConversation(qualifiedID: conversationID)

            let conversation: ZMConversation? = await context.perform {
                guard let conversation = ZMConversation.fetch(
                    with: conversationID,
                    in: context
                ) else {
                    return nil
                }

                conversation.mlsGroupID = groupID
                conversation.mlsStatus = .ready

                return conversation
            }

            guard let conversation else { return }

            await resolveOneOnOneConversationIfNeeded(
                conversation: conversation,
                oneOneOneResolver: oneOnOneResolver,
                in: context
            )
        } catch {
            WireLogger.mls.warn("MLS event processor aborting processing welcome message: \(String(describing: error))")
            return
        }
    }

    private func resolveOneOnOneConversationIfNeeded(
        conversation: ZMConversation,
        oneOneOneResolver: OneOnOneResolverInterface,
        in context: NSManagedObjectContext
    ) async {
        WireLogger.mls.debug("resolving one on one conversation")

        let userID: QualifiedID? = await context.perform {
            guard conversation.conversationType == .oneOnOne else {
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

            try await context.perform {
                try context.save()
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
