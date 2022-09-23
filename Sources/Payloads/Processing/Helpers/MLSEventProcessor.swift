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

protocol MLSEventProcessing {

    func updateConversationIfNeeded(conversation: ZMConversation, groupID: String?, context: NSManagedObjectContext)
    func process(welcomeMessage: String, in context: NSManagedObjectContext)
    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext)
    func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext)

}

class MLSEventProcessor: MLSEventProcessing {

    private(set) static var shared: MLSEventProcessing = MLSEventProcessor()

    // MARK: - Update conversation

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        groupID: String?,
        context: NSManagedObjectContext
    ) {
        Logging.mls.info("MLS event processor updating conversation if needed")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .conversationUpdate, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = MLSGroupID(from: groupID) else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingGroupID)
        }

        if conversation.mlsGroupID == nil {
           conversation.mlsGroupID = mlsGroupID
           Logging.mls.info("MLS event processor set the group ID to value: (\(mlsGroupID)) for conversation: (\(String(describing: conversation.qualifiedID))")
        }

        guard let mlsController = context.mlsController else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingMLSController)
        }

        let previousStatus = conversation.mlsStatus
        let conversationExists = mlsController.conversationExists(groupID: mlsGroupID)
        conversation.mlsStatus = conversationExists ? .ready : .pendingJoin

        context.saveOrRollback()

        Logging.mls.info(
            "MLS event processor updated previous mlsStatus (\(String(describing: previousStatus))) with new value (\(String(describing: conversation.mlsStatus))) for conversation (\(String(describing: conversation.qualifiedID)))"
        )
    }

    // MARK: - Joining new conversations

    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext) {
        Logging.mls.info("MLS event processor is adding group to join")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .joiningGroup, withReason: .notMLSConversation)
        }

        guard let groupID = conversation.mlsGroupID else {
            return logWarn(aborting: .joiningGroup, withReason: .missingGroupID)
        }

        guard let mlsController = context.mlsController else {
            return logWarn(aborting: .joiningGroup, withReason: .missingMLSController)
        }

        guard let status = conversation.mlsStatus, status.isPendingJoin else {
            return logWarn(aborting: .joiningGroup, withReason: .other(reason: "MLS status is not .pendingJoin"))
        }

        mlsController.registerPendingJoin(groupID)
        Logging.mls.info("MLS event processor added group (\(groupID)) to be joined")
    }

    // MARK: - Process welcome message

    func process(welcomeMessage: String, in context: NSManagedObjectContext) {
        Logging.mls.info("MLS event processor is processing welcome message")

        guard let mlsController = context.mlsController else {
            return logWarn(aborting: .processingWelcome, withReason: .missingMLSController)
        }

        do {
            let groupID = try mlsController.processWelcomeMessage(welcomeMessage: welcomeMessage)

            guard let conversation = ZMConversation.fetch(with: groupID, in: context) else {
                return logWarn(aborting: .processingWelcome, withReason: .other(reason: "conversation does not exist in db"))
            }

            conversation.mlsStatus = .ready
            context.saveOrRollback()

            Logging.mls.info(
                "MLS event processor set mlsStatus to (\(String(describing: conversation.mlsStatus)) for group (\(groupID))"
            )
        } catch {
            return Logging.mls.warn("MLS event processor aborting processing welcome message: \(String(describing: error))")
        }
    }

    // MARK: - Wipe conversation

    func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext) {
        Logging.mls.info("MLS event processor is wiping conversation")

        guard conversation.messageProtocol == .mls else {
            return logWarn(aborting: .conversationWipe, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = conversation.mlsGroupID else {
            return logWarn(aborting: .conversationWipe, withReason: .missingGroupID)
        }

        guard let mlsController = context.mlsController else {
            return logWarn(aborting: .conversationWipe, withReason: .missingMLSController)
        }

        mlsController.wipeGroup(mlsGroupID)
    }

    // MARK: Log Helpers

    private func logWarn(aborting action: ActionLog, withReason reason: AbortReason) {
        Logging.mls.warn("MLS event processor aborting \(action.rawValue): \(reason.stringValue)")
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
        case missingMLSController
        case other(reason: String)

        var stringValue: String {
            switch self {
            case .notMLSConversation:
                return "not an MLS conversation"
            case .missingGroupID:
                return "missing group ID"
            case .missingMLSController:
                return "missing MLSController"
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
            let bytes = groupID.base64EncodedBytes
        else {
            return nil
        }

        self.init(bytes)
    }
}

extension MLSEventProcessor {

    /// Use this method to set the `MLSEventProcessor` singleton to a custom class instance
    /// Don't forget to call `MLSEventProcessor.reset()` after your test is done
    /// - Parameter mock: a custom class instance conforming to the `MLSEventProcessing` protocol
    static func setMock(_ mock: MLSEventProcessing) {
        Self.shared = mock
    }

    /// Use this method to reset the `MLSEventProcessor` singleton to its original state
    static func reset() {
        Self.shared = MLSEventProcessor()
    }
}
