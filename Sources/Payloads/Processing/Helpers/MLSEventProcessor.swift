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
    func process(welcomeMessage: String, domain: String, in context: NSManagedObjectContext)
    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext)

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
            return Logging.mls.warn("MLS event processor aborting conversation update: not an MLS conversation")
        }

        guard let mlsGroupID = MLSGroupID(from: groupID) else {
            return Logging.mls.warn("MLS event processor aborting conversation update: missing group ID")
        }

        if conversation.mlsGroupID == nil {
           conversation.mlsGroupID = mlsGroupID
           Logging.mls.info("MLS event processor set the group ID to value: (\(mlsGroupID)) for conversation: (\(String(describing: conversation.qualifiedID))")
        }

        guard let mlsController = context.mlsController else {
            return Logging.mls.warn("MLS event processor aborting conversation update: missing MLSController")
        }

        let previousStatus = conversation.mlsStatus
        let conversationExists = mlsController.conversationExists(groupID: mlsGroupID)
        conversation.mlsStatus = conversationExists ? .ready : .pendingJoin

        context.saveOrRollback()

        Logging.mls.info(
            "MLS event processor updated previous mlsStatus (\(previousStatus)) with new value (\(conversation.mlsStatus)) for conversation (\(String(describing: conversation.qualifiedID)))"
        )
    }

    // MARK: - Joining new conversations

    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext) {
        guard conversation.messageProtocol == .mls else {
            return Logging.mls.info("Message protocol is not mls")
        }

        guard let status = conversation.mlsStatus else {
            return Logging.mls.warn("Conversation's MLS status is nil")
        }

        guard let mlsGroup = MLSGroup(from: conversation) else {
            return Logging.mls.warn("Failed to create MLSGroup from conversation")
        }

        guard let mlsController = context.mlsController else {
            return Logging.mls.warn("Missing MLSController in context")
        }

        if status.isPendingJoin {
            mlsController.addGroupPendingJoin(mlsGroup)
        }
    }

    // MARK: - Process welcome message

    func process(welcomeMessage: String, domain: String, in context: NSManagedObjectContext) {
        Logging.mls.info("MLS event processor is processing welcome message")

        guard let mlsController = context.mlsController else {
            return Logging.mls.warn("MLS event processor aborting processing welcome message: missing MLSController")
        }

        do {
            let groupID = try mlsController.processWelcomeMessage(welcomeMessage: welcomeMessage)

            guard let conversation = ZMConversation.fetch(with: groupID, domain: domain, in: context) else {
                return Logging.mls.warn("MLS event processor aborting processing welcome message: conversation does not exist in db")
            }

            conversation.mlsStatus = .ready
            context.saveOrRollback()
        } catch {
            return Logging.mls.warn("MLS event processor aborting processing welcome message: \(String(describing: error))")
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
