// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public protocol MLSEventProcessing {

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        groupID: String?,
        context: NSManagedObjectContext
    )

    func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext
    )

    func joinMLSGroupWhenReady(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    )

    func wipeMLSGroup(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    )

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
        groupID: String?,
        context: NSManagedObjectContext
    ) {
        WireLogger.mls.debug("MLS event processor updating conversation if needed")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .conversationUpdate, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = conversation.mlsGroupID ?? MLSGroupID(from: groupID) else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingGroupID)
        }

        if conversation.mlsGroupID == nil {
            conversation.mlsGroupID = mlsGroupID
            WireLogger.mls.debug("set group ID \(mlsGroupID.safeForLoggingDescription) for conversation \(conversation.qualifiedID)")
        }

        guard let mlsService = context.mlsService else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingMLSService)
        }

        let conversationExists = mlsService.conversationExists(groupID: mlsGroupID)
        let previousStatus = conversation.mlsStatus
        let newStatus = conversationExists ? MLSGroupStatus.ready : .pendingJoin
        conversation.mlsStatus = newStatus
        context.saveOrRollback()

        if newStatus != previousStatus {
            WireLogger.mls.debug("conversation \(conversation.qualifiedID) status changed: \(previousStatus) -> \(newStatus))")
        }
    }

    // MARK: - Joining new conversations

    public func joinMLSGroupWhenReady(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        WireLogger.mls.info("MLS event processor is adding group to join")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .joiningGroup, withReason: .notMLSConversation)
        }

        guard let groupID = conversation.mlsGroupID else {
            return logWarn(aborting: .joiningGroup, withReason: .missingGroupID)
        }

        guard let mlsService = context.mlsService else {
            return logWarn(aborting: .joiningGroup, withReason: .missingMLSService)
        }

        guard let status = conversation.mlsStatus, status.isPendingJoin else {
            return logWarn(aborting: .joiningGroup, withReason: .other(reason: "MLS status is not .pendingJoin"))
        }

        mlsService.registerPendingJoin(groupID)
        WireLogger.mls.info("MLS event processor added group (\(groupID.safeForLoggingDescription)) to be joined")
    }

    // MARK: - Process welcome message

    public func process(
        welcomeMessage: String,
        conversationID: QualifiedID,
        in context: NSManagedObjectContext
    ) {
        WireLogger.mls.info("MLS event processor is processing welcome message")

        guard let mlsService = context.mlsService else {
            return logWarn(aborting: .processingWelcome, withReason: .missingMLSService)
        }

        do {
            let groupID = try mlsService.processWelcomeMessage(welcomeMessage: welcomeMessage)
            mlsService.uploadKeyPackagesIfNeeded()

            if let conversation = ZMConversation.fetch(with: conversationID, in: context) {
                conversation.mlsGroupID = groupID
                conversation.mlsStatus = .ready
                WireLogger.mls.info("MLS event processor set mlsStatus to ready for group \(groupID.safeForLoggingDescription)")
                context.saveOrRollback()
            } else {
                // Conversation doesn't exist locally yet, so fetch it from the backend.
                // It'll be marked as ready when it's synced locally.
                conversationService.syncConversation(qualifiedID: conversationID) {
                    // no op
                }
            }
        } catch {
            return WireLogger.mls.warn("MLS event processor aborting processing welcome message: \(String(describing: error))")
        }
    }

    // MARK: - Wipe conversation

    public func wipeMLSGroup(
        forConversation conversation: ZMConversation,
        context: NSManagedObjectContext
    ) {
        WireLogger.mls.info("MLS event processor is wiping conversation")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .conversationWipe, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = conversation.mlsGroupID else {
            return logWarn(aborting: .conversationWipe, withReason: .missingGroupID)
        }

        guard let mlsService = context.mlsService else {
            return logWarn(aborting: .conversationWipe, withReason: .missingMLSService)
        }

        mlsService.wipeGroup(mlsGroupID)
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
        case notMLSConversation
        case missingGroupID
        case missingMLSService
        case other(reason: String)

        var stringValue: String {
            switch self {
            case .notMLSConversation:
                return "not an MLS conversation"
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

extension MLSGroupStatus {
    var isPendingJoin: Bool {
        return self == .pendingJoin
    }
}

extension MLSGroupID {
    init?(from groupIdString: String?) {
        guard
            let groupID = groupIdString,
            !groupID.isEmpty,
            let bytes = groupID.base64DecodedBytes
        else {
            return nil
        }

        self.init(bytes)
    }
}
