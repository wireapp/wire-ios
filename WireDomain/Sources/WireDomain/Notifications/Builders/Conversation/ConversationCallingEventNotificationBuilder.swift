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

import GenericMessageProtocol
import WireDataModel
import WireLogging
import WireNetwork

/// Handles a calling notification (using CallKit in priority if available) related to an incoming / missed call
struct ConversationCallingEventNotificationBuilder: ConversationCallingEventNotificationBuilderProtocol {

    let context: ConversationCallingEventNotificationBuilder.Context
    let validator: ConversationCallingEventNotificationBuilder.Validator
    let accountID: UUID

    func buildContent(
        calling: Calling,
        at time: Date?,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification? {
        WireLogger.notifications.info(
            "[CALLING-DEBUG] buildContent called - conversationID: \(conversationID.id.safeForLoggingDescription), senderID: \(senderID.id.safeForLoggingDescription), calling.content: \(calling.content)",
            attributes: .newNSE, .safePublic
        )

        guard let callContent: CallContent = .decode(from: calling) else {
            WireLogger.notifications.warn(
                "[CALLING-DEBUG] Failed to decode CallContent",
                attributes: .newNSE, .safePublic
            )
            return nil
        }

        WireLogger.notifications.info(
            "[CALLING-DEBUG] CallContent decoded - type: \(callContent.type), isIncomingCall: \(callContent.isIncomingCall), isAnsweredElsewhere: \(callContent.isAnsweredElsewhere), isEndCall: \(callContent.isEndCall), responded: \(callContent.responded)",
            attributes: .newNSE, .safePublic
        )
        var resolvedConversationID: ConversationID {
            let callingConversationID = calling.qualifiedConversationID
            guard !callingConversationID.id.isEmpty,
                  let conversationUUID = UUID(uuidString: callingConversationID.id)
            else {
                return conversationID
            }
            return QualifiedID(id: conversationUUID, domain: callingConversationID.domain)
        }
        let displayCallKitNotification = await validator.validateCallKitNotification(
            conversationID: resolvedConversationID,
            senderID: senderID,
            accountID: accountID,
            eventTimestamp: time,
            callContent: callContent
        )

        let displayCallNotification = await validator.validateCallNotification(
            conversationID: resolvedConversationID,
            senderID: senderID,
            eventTimestamp: time,
            callContent: callContent
        )

        WireLogger.notifications.info(
            "[CALLING-DEBUG] Validation results - displayCallKitNotification: \(displayCallKitNotification), displayCallNotification: \(displayCallNotification)",
            attributes: .newNSE, .safePublic
        )

        if displayCallKitNotification {
            // First, let's try to return a CallKit notification if possible.
            WireLogger.notifications.info(
                "[CALLING-DEBUG] Building CallKit notification",
                attributes: .newNSE, .safePublic
            )
            let notification = await buildCallKitNotification(
                callContent: callContent,
                accountID: accountID,
                conversationID: resolvedConversationID,
                senderID: senderID
            )
            WireLogger.notifications.info(
                "[CALLING-DEBUG] CallKit notification built",
                attributes: .newNSE, .safePublic
            )
            return notification

        } else if displayCallNotification {
            // If not, try to return a regular call notification.
            WireLogger.notifications.info(
                "[CALLING-DEBUG] Building regular call notification",
                attributes: .newNSE, .safePublic
            )
            return await buildCallNotification(
                callContent: callContent,
                senderID: senderID,
                conversationID: resolvedConversationID
            )
        } else {
            // Else, this is not a call, return nil.
            WireLogger.notifications.warn(
                "[CALLING-DEBUG] No notification will be generated (both validations failed)",
                attributes: .newNSE, .safePublic
            )
            return nil
        }

    }

    // MARK: - Build CallKit notification

    private func buildCallKitNotification(
        callContent: CallContent,
        accountID: UUID,
        conversationID: ConversationID,
        senderID: UserID
    ) async -> UserNotification {
        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": conversationID.id.uuidString,
            "shouldRing": callContent.isIncomingCall,
            "callerName": await makeCallKitTitle(
                conversationID: conversationID,
                senderID: senderID
            ) ?? "",
            "hasVideo": callContent.isVideo
        ]

        return .callKit(callKitContent)
    }

    // MARK: - Build call notifications

    private func buildCallNotification(
        callContent: CallContent,
        senderID: UserID,
        conversationID: ConversationID
    ) async -> UserNotification {
        let conversation = await context.getConversation(conversationID: conversationID)
        let caller = await context.getCaller(senderID: senderID)
        let selfUser = await context.getSelfUser()
        let selfUserID = await context.selfUserID(selfUser: selfUser)
        let callerID = context.callerID(callContent: callContent)
        let senderName = await context.callerName(caller: caller)
        let conversationName = await context.conversationName(conversation: conversation)
        let teamName = await context.teamName(selfUser: selfUser)
        let isGroupConversation = await context.isGroupConversation(conversation: conversation)

        if callContent.isIncomingCall {
            return buildIncomingCallNotification(
                selfUserID: selfUserID,
                senderID: senderID.id,
                callerID: callerID,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                conversationName: conversationName,
                teamName: teamName,
                isGroupConversation: isGroupConversation,
                isVideo: callContent.isVideo
            )
        } else { // Missed call
            return await buildMissedCallNotification(
                selfUserID: selfUserID,
                senderID: senderID.id,
                callerID: callerID,
                conversation: conversation,
                conversationID: conversationID,
                senderName: senderName,
                conversationName: conversationName,
                teamName: teamName,
                isGroupConversation: isGroupConversation
            )
        }
    }

    private func buildIncomingCallNotification(
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

        if let title = makeCallTitle(
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
        content.categoryIdentifier = makeCategory(isIncomingCall: true)
        content.sound = makeSound(isIncomingCall: true)
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            callerID: callerID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

        return .text(content)
    }

    private func buildMissedCallNotification(
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

        if let title = makeCallTitle(
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
        content.categoryIdentifier = makeCategory(isIncomingCall: false)
        content.sound = makeSound(isIncomingCall: false)
        content.userInfo = makeUserInfo(
            selfUserID: selfUserID,
            senderID: senderID,
            callerID: callerID,
            conversationID: conversationID
        )
        content.threadIdentifier = conversationID.id.transportString()

        await context.increaseReadCount(
            conversation: conversation
        )

        return .text(content)
    }

    // MARK: - Helpers

    private func makeCallKitTitle(
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

        let format: NotificationTitle.MessageTitleDescriptor? = if isGroupConversation, let conversationName {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else if let callerName {
            if let teamName {
                .senderInTeam(sender: callerName, team: teamName)
            } else {
                .sender(sender: callerName)
            }
        } else {
            nil
        }

        guard let format else { return nil }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

    private func makeCallTitle(
        isGroupConversation: Bool,
        callerName: String?,
        conversationName: String?,
        teamName: String?
    ) -> String? {

        let format: NotificationTitle.MessageTitleDescriptor? = if isGroupConversation, let conversationName {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else if let callerName {
            if let teamName {
                .senderInTeam(sender: callerName, team: teamName)
            } else {
                .sender(sender: callerName)
            }
        } else {
            nil
        }

        guard let format else { return nil }

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

    private func makeSound(isIncomingCall: Bool) -> UNNotificationSound {
        let notificationSound = if isIncomingCall {
            NotificationSound.call
        } else {
            NotificationSound.default
        }

        let notificationSoundName = UNNotificationSoundName(notificationSound.rawValue)
        return UNNotificationSound(named: notificationSoundName)
    }

    private func makeCategory(isIncomingCall: Bool) -> String {
        if isIncomingCall {
            NotificationCategory.incomingCall.rawValue
        } else {
            NotificationCategory.missedCall.rawValue
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
        userInfo[NotificationUserInfoKey.conversationID] = conversationID.id.uuidString

        return userInfo
    }
}

extension ConversationCallingEventNotificationBuilder {
    struct Validator {

        private enum Constants {
            static let isAvsReady = "isAVSReady"
            static let isCallKitAvailable = "isCallKitAvailable"
            static let loadedUserSessions = "loadedUserSessions"
            static let knownCalls = "knownCalls"
        }

        let userLocalStore: any UserLocalStoreProtocol
        let conversationLocalStore: any ConversationLocalStoreProtocol
        let userDefaults: UserDefaults

        /// In priority, we'll try to validate a CallKit notification to show to the user
        func validateCallKitNotification(
            conversationID: ConversationID,
            senderID: UserID,
            accountID: UUID,
            eventTimestamp: Date?,
            callContent: CallContent
        ) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
                domain: conversationID.domain
            )

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

            let handle = "\(accountID.transportString())+\(conversationID.id.transportString())"
            let knownCallHandles = userDefaults.object(forKey: Constants.knownCalls) as? [String] ?? []
            let wasCallHandleReported = knownCallHandles.contains(handle)

            let initiatesRinging = callContent.isIncomingCall && !wasCallHandleReported
            let terminatesRinging = (
                callContent.isEndCall || callContent.isAnsweredElsewhere || callContent
                    .isRejected
            ) && wasCallHandleReported

            let isValidState = initiatesRinging || terminatesRinging

            let serverTimeDelta = await conversationLocalStore.fetchServerTimeDelta()
            let currentTimestamp = Date.now.addingTimeInterval(serverTimeDelta)
            let isCallTimeOut = eventTimestamp != nil ? Int(currentTimestamp.timeIntervalSince(eventTimestamp!)) > 30 :
                true

            return !needsToBeUpdatedFromBackend
                && !isConversationMuted
                && !isConversationForcedReadOnly
                && isAVSReady
                && isCallKitReady
                && isUserSessionLoaded
                && !isCallTimeOut
                && isValidState
        }

        /// When a CallKit notification cannot be displayed, we'll try to validate a regular call notification.
        func validateCallNotification(
            conversationID: ConversationID,
            senderID: UserID,
            eventTimestamp: Date?,
            callContent: CallContent
        ) async -> Bool {
            let conversation = await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
                domain: conversationID.domain
            )

            let selfUser = await userLocalStore.fetchSelfUser()

            let caller = await userLocalStore.fetchOrCreateUser(
                id: senderID.id,
                domain: senderID.domain
            )

            let serverTimeDelta = await conversationLocalStore.fetchServerTimeDelta()
            let currentTimestamp = Date.now.addingTimeInterval(serverTimeDelta)

            let mutedMessagesTypes = await conversationLocalStore
                .conversationMutedMessageTypesIncludingAvailability(conversation)
            let isConversationMuted = mutedMessagesTypes == .all
            let isCallTimeOut = eventTimestamp != nil ? Int(currentTimestamp.timeIntervalSince(eventTimestamp!)) > 30 :
                true
            let isCallerSelf = selfUser == caller

            let isIncomingCall = callContent.isIncomingCall
            let isEndCall = callContent.isEndCall
            let isValidState = isIncomingCall || isEndCall

            return isValidState
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
            await conversationLocalStore.fetchOrCreateConversation(
                id: conversationID.id,
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
                id: senderID.id,
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
