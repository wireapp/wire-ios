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
struct CallKitNotificationBuilder: NotificationBuilder {

    private enum CallKitState: Equatable {
        case initiatesRinging
        case terminatesRinging
        case unhandled

        init(callContent: CallContent, wasCallHandleReported: Bool) {
            let isStartCall = callContent.type.isOne(of: ["SETUP", "GROUPSTART", "CONFSTART"])
            let isIncomingCall = isStartCall && !callContent.resp
            let isEndCall = callContent.type.isOne(of: ["CANCEL", "GROUPEND", "CONFEND"])
            let isAnsweredElsewhere = isStartCall && callContent.resp
            let isRejected = callContent.type == "REJECT"

            if isIncomingCall && !wasCallHandleReported {
                self = .initiatesRinging
            } else if isEndCall || isAnsweredElsewhere || isRejected {
                self = .terminatesRinging
            } else {
                self = .unhandled
            }
        }
    }

    private struct Context {
        let accountID: String
        let conversationID: String
        let isGroupConversation: Bool
        let callerName: String?
        let conversationName: String?
        let teamName: String?
        let shouldRing: Bool
        let isVideo: Bool
    }

    private struct Validator {
        let isConversationMuted: Bool
        let conversationNeedsBackendUpdate: Bool
        let isConversationForcedReadOnly: Bool
        let isAVSReady: Bool
        let isCallKitReady: Bool
        let isUserSessionLoaded: Bool
        let isCallerSelf: Bool
        let isCallStateValid: Bool

        func validate() -> Bool {
            !conversationNeedsBackendUpdate
                && !isConversationMuted
                && !isConversationForcedReadOnly
                && isAVSReady
                && isCallKitReady
                && isUserSessionLoaded
                && isCallStateValid
        }
    }

    private let context: Context
    private let validator: Validator

    init?(
        calling: Calling,
        conversationID: ConversationID,
        senderID: UserID,
        accountID: UUID,
        userDefaults: UserDefaults = .standard,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) async {
        guard let callContent: CallContent = .decode(from: calling) else {
            return nil
        }

        let handle = "\(accountID.transportString())+\(conversationID.uuid.transportString())"
        let knownCallHandles = userDefaults.object(forKey: "knownCalls") as? [String] ?? []
        let wasCallHandleReported = knownCallHandles.contains(handle)

        let callKitState = CallKitState(
            callContent: callContent,
            wasCallHandleReported: wasCallHandleReported
        )

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
        let isAVSReady = userDefaults.bool(forKey: "isAVSReady")
        let isCallKitReady = userDefaults.bool(forKey: "isCallKitAvailable")
        let loadedUserSessions = userDefaults.object(forKey: "loadedUserSessions") as? [String] ?? []
        let loaderUserSessionsIDs = loadedUserSessions.compactMap(UUID.init(uuidString:))
        let isUserSessionLoaded = loaderUserSessionsIDs.contains(accountID)

        self.validator = Validator(
            isConversationMuted: isConversationMuted,
            conversationNeedsBackendUpdate: needsToBeUpdatedFromBackend,
            isConversationForcedReadOnly: isConversationForcedReadOnly,
            isAVSReady: isAVSReady,
            isCallKitReady: isCallKitReady,
            isUserSessionLoaded: isUserSessionLoaded,
            isCallerSelf: selfUser == caller,
            isCallStateValid: callKitState != .unhandled
        )

        // Context

        let isGroupConversation = await conversationLocalStore.isGroupConversation(conversation)
        let conversationName = await conversationLocalStore.name(for: conversation)
        let teamName = await userLocalStore.teamName(for: selfUser)
        let callerName = await userLocalStore.name(for: caller)

        self.context = Context(
            accountID: accountID.uuidString,
            conversationID: conversationID.uuid.uuidString,
            isGroupConversation: isGroupConversation,
            callerName: callerName,
            conversationName: conversationName,
            teamName: teamName,
            shouldRing: callKitState == .initiatesRinging,
            isVideo: callContent.properties?.isVideo ?? false
        )
    }

    func shouldBuildNotification() async -> Bool {
        validator.validate()
    }

    func buildContent() async -> UserNotification {
        let callKitContent: [String: Any] = [
            "accountID": context.accountID,
            "conversationID": context.conversationID,
            "shouldRing": context.shouldRing,
            "callerName": makeTitle() ?? "",
            "hasVideo": context.isVideo
        ]

        return .callKit(callKitContent)
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

}
