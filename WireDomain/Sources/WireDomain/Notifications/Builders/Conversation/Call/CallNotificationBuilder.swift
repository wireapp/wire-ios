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

/// Handles a regular push notification related to an incoming / missed call
struct CallNotificationBuilder {

    enum CallState: Equatable {
        case incomingCall(video: Bool)
        case missedCall
        case unhandled

        init(callContent: CallContent) {
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

            if isIncomingCall {
                self = .incomingCall(video: callContent.properties?.isVideo ?? false)
            } else if isEndCall {
                self = .missedCall
            } else {
                self = .unhandled
            }

        }
    }

    let context: CallNotificationBuilder.Context
    let validator: CallNotificationBuilder.Validator

    func buildContent(
        calling: Calling,
        at time: Date?,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification? {
        guard let callContent: CallContent = .decode(from: calling) else {
            return nil
        }
        
        let callState = CallState(callContent: callContent)
        
        let canDisplayNotification = await validator.validate(
            callState: callState,
            time: time,
            senderID: senderID,
            conversationID: conversationID
        )
        
        guard canDisplayNotification else {
            return nil
        }
        
        let conversation = await context.getConversation(conversationID: conversationID)
        let caller = await context.getCaller(senderID: senderID)
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        let callerID = context.callerID(callContent: callContent)
        let senderName = await context.callerName(caller: caller)
        let conversationName = await context.conversationName(conversation: conversation)
        let teamName = await context.teamName(selfUser: selfUser)
        let isGroupConversation = await context.isGroupConversation(conversation: conversation)
        
        switch callState {
        case let .incomingCall(isVideo):
            return buildIncomingCallNotification(
                callState: callState,
                selfUserID: selfUserID,
                senderID: senderID.uuid,
                callerID: callerID,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                conversationName: conversationName,
                teamName: teamName,
                isGroupConversation: isGroupConversation,
                isVideo: isVideo
            )
            
        case .missedCall:
            return await buildMissedCallNotification(
                callState: callState,
                selfUserID: selfUserID,
                senderID: senderID.uuid,
                callerID: callerID,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                conversationName: conversationName,
                teamName: teamName,
                isGroupConversation: isGroupConversation
            )
        case .unhandled:
            fatalError()
        }
    }

    // MARK: - Build notifications

    private func buildIncomingCallNotification(
        callState: CallState,
        selfUserID: UUID,
        senderID: UUID,
        callerID: UUID?,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderName: String?,
        conversationName: String?,
        teamName: String?,
        isGroupConversation: Bool,
        isVideo: Bool
    ) -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            callerName: senderName,
            conversationName: conversationName,
            teamName: teamName
        ) {
            content.title = title
        }

        let body = if isGroupConversation, let senderName {
            String.formated(
                key: isVideo ? "push.notification.body.videoCallFromSender" :
                    "push.notification.body.audioCallFromSender", bundle: .module, senderName
            )
        } else {
            String.localized(
                key: isVideo ? "push.notification.body.videoCall" : "push.notification.body.audioCall", bundle: .module
            )
        }

        content.body = body
        content.categoryIdentifier = makeCategory(callState: callState)
        content.sound = makeSound(callState: callState)
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            callerID: callerID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildMissedCallNotification(
        callState: CallState,
        selfUserID: UUID,
        senderID: UUID,
        callerID: UUID?,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderName: String?,
        conversationName: String?,
        teamName: String?,
        isGroupConversation: Bool
    ) async -> UserNotification {
        let content = UNMutableNotificationContent()

        if let title = makeTitle(
            isGroupConversation: isGroupConversation,
            callerName: senderName,
            conversationName: conversationName,
            teamName: teamName
        ) {
            content.title = title
        }

        let body = if isGroupConversation, let senderName {
            String.formated(key: "push.notification.body.senderCalled", bundle: .module, senderName)
        } else {
            String.localized(key: "push.notification.body.missedCall", bundle: .module)
        }

        content.body = body
        content.categoryIdentifier = makeCategory(callState: callState)
        content.sound = makeSound(callState: callState)
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            callerID: callerID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.uuid.transportString()

        await context.increaseReadCount(
            conversation: conversation
        )

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle(
        isGroupConversation: Bool,
        callerName: String?,
        conversationName: String?,
        teamName: String?
    ) -> String? {

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

    private func makeSound(callState: CallState) -> UNNotificationSound {
        let notificationSound = switch callState {
        case .incomingCall:
            NotificationSound.call
        case .missedCall:
            NotificationSound.default
        case .unhandled:
            fatalError()
        }

        let notificationSoundName = UNNotificationSoundName(notificationSound.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory(callState: CallState) -> String {
        switch callState {
        case .incomingCall:
            NotificationCategory.incomingCall.rawValue
        case .missedCall:
            NotificationCategory.missedCall.rawValue
        case .unhandled:
            fatalError()
        }
    }

    private func makeUserInfo(
        selfUserID: UUID,
        senderID: UUID,
        callerID: UUID?,
        conversationID: ConversationID
    ) -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = selfUserID.uuidString
        userInfo[NotificationUserInfoKey.senderID] = callerID?.uuidString
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.uuid.uuidString

        return userInfo
    }
}

extension CallNotificationBuilder {
    struct Validator {
        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol

        func validate(
            callState: CallState,
            time: Date?,
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

            let mutedMessagesTypes = await conversationLocalStore
                .conversationMutedMessageTypesIncludingAvailability(conversation)
            let isConversationMuted = mutedMessagesTypes == .all
            let isCallTimeOut = time != nil ? Int(Date.now.timeIntervalSince(time!)) > 30 : true
            let isCallerSelf = selfUser == caller
            
            return callState != .unhandled
                && !isCallerSelf
                && !isConversationMuted
                && !isCallTimeOut
        }
    }
    
    struct Context {
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userLocalStore: any UserLocalStoreProtocol
        
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
        
        func selfUserID(selfUser: ZMUser) async -> UUID {
            await userLocalStore.id(for: selfUser)
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
        
        func callerID(
            callContent: CallContent
        ) -> UUID? {
            callContent.callerUserID.flatMap(UUID.init(transportString:))
        }
        
        func increaseReadCount(
            conversation: ZMConversation
        ) async {
            await conversationLocalStore.increaseUnreadCount(
                for: conversation
            )
        }

    }
}
