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
struct CallNotificationBuilder: NotificationBuilder {

    private enum CallState: Equatable {
        case incomingCall(video: Bool)
        case missedCall
        case unhandled

        init(callContent: CallContent) {
            let isStartCall = callContent.type.isOne(of: ["SETUP", "GROUPSTART", "CONFSTART"])
            let isIncomingCall = isStartCall && !callContent.resp
            let isEndCall = callContent.type.isOne(of: ["CANCEL", "GROUPEND", "CONFEND"])

            if isIncomingCall {
                self = .incomingCall(video: callContent.properties?.isVideo ?? false)
            } else if isEndCall {
                self = .missedCall
            } else {
                self = .unhandled
            }

        }
    }

    private struct Context {
        let conversation: ZMConversation
        let callState: CallState
        let callerID: UUID?
        let callerName: String?
        let conversationName: String?
        let isGroupConversation: Bool
        let teamName: String?
        let conversationID: WireAPI.QualifiedID
        let selfUserID: UUID
    }

    private struct Validator {
        let isCallStateValid: Bool
        let isCallerSelf: Bool
        let isConversationMuted: Bool
        let isCallTimedOut: Bool

        func validate() -> Bool {
            isCallStateValid
                && !isCallerSelf
                && !isConversationMuted
                && !isCallTimedOut
        }
    }

    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let context: Context
    private let validator: Validator

    init?(
        calling: Calling,
        at time: Date?,
        conversationID: ConversationID,
        senderID: UserID,
        conversationLocalStore: ConversationLocalStoreProtocol,
        userLocalStore: UserLocalStoreProtocol
    ) async {
        guard let callContent: CallContent = .decode(from: calling) else {
            return nil
        }

        self.conversationLocalStore = conversationLocalStore

        let callState = CallState(callContent: callContent)

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

        self.validator = Validator(
            isCallStateValid: callState != .unhandled,
            isCallerSelf: selfUser == caller,
            isConversationMuted: isConversationMuted,
            isCallTimedOut: isCallTimeOut
        )

        // Context

        let conversationName = await conversationLocalStore.name(for: conversation)
        let isGroupConversation = await conversationLocalStore.isGroupConversation(conversation)
        let selfUserID = await userLocalStore.id(for: selfUser)
        let teamName = await userLocalStore.teamName(for: selfUser)
        let callerName = await userLocalStore.name(for: caller)
        let callerID = callContent.callerUserID.flatMap(UUID.init(transportString:))

        self.context = Context(
            conversation: conversation,
            callState: callState,
            callerID: callerID,
            callerName: callerName,
            conversationName: conversationName,
            isGroupConversation: isGroupConversation,
            teamName: teamName,
            conversationID: conversationID,
            selfUserID: selfUserID
        )
    }

    func shouldBuildNotification() async -> Bool {
        validator.validate()
    }

    func buildContent() async -> UserNotification {
        switch context.callState {
        case let .incomingCall(isVideo):
            buildIncomingCallNotification(isVideo: isVideo)
        case .missedCall:
            await buildMissedCallNotification()
        case .unhandled:
            fatalError()
        }
    }

    // MARK: - Build notifications

    private func buildIncomingCallNotification(isVideo: Bool) -> UserNotification {
        let content = UNMutableNotificationContent()
        let senderName = context.callerName

        if let title = makeTitle() {
            content.title = title
        }

        let body = if isVideo {
            senderName != nil ? "\(senderName!) is calling with video" : "Incoming video call"
        } else {
            senderName != nil ? "\(senderName!) is calling" : "Incoming call"
        }

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        return .text(content)
    }

    private func buildMissedCallNotification() async -> UserNotification {
        let content = UNMutableNotificationContent()
        let senderName = context.callerName

        if let title = makeTitle() {
            content.title = title
        }

        let body = senderName != nil ? "\(senderName!) called" : "Missed call"

        content.body = body
        content.categoryIdentifier = makeCategory()
        content.sound = makeSound()
        content.userInfo = makeUserInfo()
        content.threadIdentifier = context.conversationID.uuid.transportString()

        await conversationLocalStore.increaseUnreadCount(
            for: context.conversation
        )

        return .text(content)
    }

    // MARK: - Helpers

    private func makeTitle() -> String? {
        let isGroupConversation = context.isGroupConversation
        let teamName = context.teamName
        let conversationName = context.conversationName
        let callerName = context.callerName

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

    private func makeSound() -> UNNotificationSound {
        let notificationSound = switch context.callState {
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

    private func makeCategory() -> String {
        switch context.callState {
        case .incomingCall:
            NotificationCategory.incomingCall.rawValue
        case .missedCall:
            NotificationCategory.missedCall.rawValue
        case .unhandled:
            fatalError()
        }
    }

    private func makeUserInfo() -> [AnyHashable: Any] {
        var userInfo: [AnyHashable: Any] = [:]

        userInfo[NotificationUserInfoKey.selfUserID] = context.selfUserID
        userInfo[NotificationUserInfoKey.senderID] = context.callerID
        userInfo[NotificationUserInfoKey.conversationID] = context.conversationID.uuid

        return userInfo
    }
}
