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

// sourcery: AutoMockable
protocol MLSEventProcessing {

    func updateConversationIfNeeded(conversation: ZMConversation, groupID: String?, context: NSManagedObjectContext) async
    func process(welcomeMessage: String, in context: NSManagedObjectContext) async
    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext)
    func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext) async

}

final class MLSEventProcessor: MLSEventProcessing {

    private(set) static var shared: MLSEventProcessing = MLSEventProcessor()

    // MARK: - Update conversation

    func updateConversationIfNeeded(
        conversation: ZMConversation,
        groupID: String?,
        context: NSManagedObjectContext
    ) async {
        WireLogger.mls.info("MLS event processor updating conversation if needed")

        guard await context.perform({ conversation.messageProtocol }) == .mls else {
            return logWarn(aborting: .conversationUpdate, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = await context.perform({ conversation.mlsGroupID }) ?? MLSGroupID(from: groupID) else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingGroupID)
        }

        await context.perform {
            if conversation.mlsGroupID == nil {
                conversation.mlsGroupID = mlsGroupID
                WireLogger.mls.info("MLS event processor set the group ID to value: (\(mlsGroupID)) for conversation: (\(String(describing: conversation.qualifiedID))")
            }
        }

        guard let mlsService = await context.perform({ context.mlsService }) else {
            return logWarn(aborting: .conversationUpdate, withReason: .missingMLSService)
        }

        let previousStatus = await context.perform { conversation.mlsStatus }
        let conversationExists = await mlsService.conversationExists(groupID: mlsGroupID)

        await context.perform {
            conversation.mlsStatus = conversationExists ? .ready : .pendingJoin
            context.saveOrRollback()
            WireLogger.mls.info(
                "MLS event processor updated previous mlsStatus (\(String(describing: previousStatus))) with new value (\(String(describing: conversation.mlsStatus))) for conversation (\(String(describing: conversation.qualifiedID)))"
            )
        }
    }

    // MARK: - Joining new conversations

    /// - Note: must be executed on syncContext
    func joinMLSGroupWhenReady(forConversation conversation: ZMConversation, context: NSManagedObjectContext) {
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

    func process(welcomeMessage: String, in context: NSManagedObjectContext) async {
        WireLogger.mls.info("MLS event processor is processing welcome message")

        let mlsService = await context.perform { context.mlsService }
        guard let mlsService else {
            return logWarn(aborting: .processingWelcome, withReason: .missingMLSService)
        }

        do {
            let groupID = try await mlsService.processWelcomeMessage(welcomeMessage: welcomeMessage)

            await context.perform {

                guard let conversation = ZMConversation.fetch(with: groupID, in: context) else {
                    return self.logWarn(aborting: .processingWelcome, withReason: .other(reason: "conversation does not exist in db"))
                }
                conversation.mlsStatus = .ready
                context.saveOrRollback()

                WireLogger.mls.info(
                    "MLS event processor set mlsStatus to (\(String(describing: conversation.mlsStatus)) for group (\(groupID.safeForLoggingDescription))"
                )
            }
        } catch {
            return WireLogger.mls.warn("MLS event processor aborting processing welcome message: \(String(describing: error))")
        }
    }

    // MARK: - Wipe conversation

    func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext) async {
        WireLogger.mls.info("MLS event processor is wiping conversation")

        guard await context.perform({ conversation.messageProtocol }) == .mls else {
            return logWarn(aborting: .conversationWipe, withReason: .notMLSConversation)
        }

        guard let mlsGroupID = await context.perform({ conversation.mlsGroupID }) else {
            return logWarn(aborting: .conversationWipe, withReason: .missingGroupID)
        }

        guard let mlsService = await context.perform({ context.mlsService }) else {
            return logWarn(aborting: .conversationWipe, withReason: .missingMLSService)
        }

        await mlsService.wipeGroup(mlsGroupID)
    }

    // MARK: Log Helpers

    private func logWarn(aborting action: ActionLog, withReason reason: AbortReason) {
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
