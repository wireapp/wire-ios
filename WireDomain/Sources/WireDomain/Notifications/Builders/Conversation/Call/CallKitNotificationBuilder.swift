//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPI
import WireDataModel
import WireLogging

/// Handles a `CallKit` notification related to an incoming / ending call
struct CallKitNotificationBuilder {

    enum CallKitState: Equatable {
        case initiatesRinging
        case terminatesRinging
        case unhandled

        init(callContent: CallContent, wasCallHandleReported: Bool) {
            let isStartCall = callContent.type.isOne(
                of: [
                    CallType.setup,
                    CallType.groupStart,
                    CallType.confStart
                ]
            )
            let isIncomingCall = isStartCall && !callContent.responded
            let isEndCall = callContent.type.isOne(
                of: [
                    CallType.cancel,
                    CallType.groupEnd,
                    CallType.confEnd
                ]
            )
            let isAnsweredElsewhere = isStartCall && callContent.responded
            let isRejected = callContent.type == CallType.reject

            if isIncomingCall, !wasCallHandleReported {
                self = .initiatesRinging
            } else if isEndCall || isAnsweredElsewhere || isRejected, wasCallHandleReported {
                self = .terminatesRinging
            } else {
                self = .unhandled
            }
        }
    }

    let context: CallKitNotificationBuilder.Context
    let validator: CallKitNotificationBuilder.Validator
    let accountID: UUID
    
    func buildContent(
        calling: Calling,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification? {
        guard let callContent: CallContent = .decode(from: calling) else {
            return nil
        }
        
        let callKitState = context.callKitState(
            callContent: callContent,
            accountID: accountID,
            conversationID: conversationID
        )
        
        let canDisplayNotification = await validator.validate(
            callKitState: callKitState,
            accountID: accountID,
            senderID: senderID,
            conversationID: conversationID
        )
        
        guard canDisplayNotification else {
            return nil
        }
        
        let callKitContent: [String: Any] = [
            "accountID": accountID,
            "conversationID": conversationID,
            "shouldRing": context.shouldRing,
            "callerName": await makeTitle(
                conversationID: conversationID,
                senderID: senderID
            ) ?? "",
            "hasVideo": context.isVideo
        ]

        return .callKit(callKitContent)
    }

    // MARK: - Helpers

    private func makeTitle(
        conversationID: ConversationID,
        senderID: UserID
    ) async -> String? {
        let conversation = await context.getConversation(
            conversationID: conversationID
        )
        
        let selfUser = await context.getSelfUser()
        let caller = await context.getCaller(
            senderID: senderID
        )
        
        let isGroupConversation = await context.isGroupConversation(
            conversation: conversation
        )
        
        let teamName = await context.teamName(
            selfUser: selfUser
        )
        
        let conversationName = await context.conversationName(
            conversation: conversation
        )
        
        let callerName = await context.callerName(
            caller: caller
        )

        guard let conversationName, let callerName else {
            return nil
        }

        let format: NotificationTitle.MessageTitleDescriptor = if isGroupConversation {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else {
            if let teamName {
                .senderInTeam(sender: callerName, team: teamName)
            } else {
                .sender(sender: callerName)
            }
        }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

}

extension CallKitNotificationBuilder {
    struct Validator {
        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let messageLocalStore: any MessageLocalStoreProtocol
        let userDefaults: UserDefaults
        
        private enum Constants {
            static let isAvsReady = "isAVSReady"
            static let isCallKitAvailable = "isCallKitAvailable"
            static let loadedUserSessions = "loadedUserSessions"
        }

        func validate(
            callKitState: CallKitState,
            accountID: UUID,
            senderID: UserID,
            conversationID: ConversationID
        ) async -> Bool {
            
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )
            
            let selfUser = await userLocalStore.fetchSelfUser()
            let caller = await userLocalStore.fetchOrCreateUser(
                id: senderID.uuid,
                domain: senderID.domain
            )

            // Validation criteria

            let needsToBeUpdatedFromBackend = await conversationLocalStore.conversationNeedsBackendUpdate(conversation)
            let mutedMessagesTypes = await conversationLocalStore
                .conversationMutedMessageTypesIncludingAvailability(conversation)
            let isConversationMuted = mutedMessagesTypes == .all
            let isConversationForcedReadOnly = await conversationLocalStore.isConversationForcedReadOnly(conversation)
            let isAVSReady = userDefaults.bool(forKey: Constants.isAvsReady)
            let isCallKitReady = userDefaults.bool(forKey: Constants.isCallKitAvailable)
            let loadedUserSessions = userDefaults.object(forKey: Constants.loadedUserSessions) as? [String] ?? []
            let loaderUserSessionsIDs = loadedUserSessions.compactMap(UUID.init(uuidString:))
            let isUserSessionLoaded = loaderUserSessionsIDs.contains(accountID)

            return !needsToBeUpdatedFromBackend
                && !isConversationMuted
                && !isConversationForcedReadOnly
                && isAVSReady
                && isCallKitReady
                && isUserSessionLoaded
                && callKitState != .unhandled
        }
    }
    
    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol
        let userDefaults: UserDefaults
        
        private enum Constants {
            static let knownCalls = "knownCalls"
        }
        
        func getConversation(
            conversationID: ConversationID
        ) async -> ZMConversation {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )
        }
        
        func getSelfUser() async -> ZMUser {
            await userLocalStore.fetchSelfUser()
        }
        
        func getCaller(
            senderID: UserID
        ) async -> ZMUser {
            await userLocalStore.fetchOrCreateUser(
                id: senderID.uuid,
                domain: senderID.domain
            )
        }
        
        func isGroupConversation(conversation: ZMConversation) async -> Bool {
            await conversationLocalStore.isGroupConversation(conversation)
        }
        
        func callerName(
            caller: ZMUser
        ) async -> String? {
            await userLocalStore.name(for: caller)
        }
        
        func conversationName(
            conversation: ZMConversation
        ) async -> String? {
            await conversationLocalStore.name(for: conversation)
        }
        
        func teamName(
            selfUser: ZMUser
        ) async -> String? {
            await userLocalStore.teamName(for: selfUser)
        }
        
        func callKitState(
            callContent: CallContent,
            accountID: UUID,
            conversationID: ConversationID
        ) -> CallKitState {
            let handle = "\(accountID.transportString())+\(conversationID.uuid.transportString())"
            let knownCallHandles = userDefaults.object(forKey: Constants.knownCalls) as? [String] ?? []
            let wasCallHandleReported = knownCallHandles.contains(handle)

            return CallKitState(
                callContent: callContent,
                wasCallHandleReported: wasCallHandleReported
            )
        }
        
        func shouldRing(
            callKitState: CallKitState
        ) -> Bool {
            callKitState == .initiatesRinging
        }
        
        func isVideo(
            callContent: CallContent
        ) -> Bool {
            callContent.properties?.isVideo ?? false
        }
        
    }
}
