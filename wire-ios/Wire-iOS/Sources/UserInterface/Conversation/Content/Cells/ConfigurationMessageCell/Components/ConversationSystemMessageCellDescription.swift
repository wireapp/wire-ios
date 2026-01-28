//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import UIKit
import WireDataModel
import WireLogging
import WireSyncEngine

enum ConversationSystemMessageCellDescription {

    static func cells(
        for message: ZMConversationMessage,
        isCollapsed: Bool,
        buttonAction: Completion?,
        selfUser: any UserType,
        accentColor: UIColor,
        userSession: UserSession
    ) -> [AnyConversationMessageCellDescription] {

        guard let systemMessageData = message.systemMessageData,
              let sender = message.senderUser,
              let conversation = message.conversationLike
        else {
            assertionFailure("Invalid system message")
            return []
        }

        switch systemMessageData.systemMessageType {
        case .connectionRequest, .connectionUpdate, .usingNewDevice, .reactivatedDevice:
            break // Deprecated

        case .conversationNameChanged:
            guard let newName = systemMessageData.text else {
                fallthrough
            }

            let renamedCell = ConversationRenamedSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                sender: sender,
                newName: newName
            )
            return [AnyConversationMessageCellDescription(renamedCell)]

        case .missedCall:
            let missedCallCell = ConversationMissedCallSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )
            return [AnyConversationMessageCellDescription(missedCallCell)]

        case .performedCall:
            // [WPB-6988] removed system message for call ends.
            return []

        case .messageDeletedForEveryone:
            let senderCell = ConversationSenderMessageCellDescription(
                sender: sender,
                selfUser: selfUser,
                message: message
            )
            return [AnyConversationMessageCellDescription(senderCell)]

        case .messageTimerUpdate:
            guard let timer = systemMessageData.messageTimer else {
                fallthrough
            }

            let timerCell = ConversationMessageTimerSystemMessageCellDescription(
                state: .updated(message: message, data: systemMessageData, timer: timer, sender: sender)
            )
            return [AnyConversationMessageCellDescription(timerCell)]

        case .conversationIsSecure:
            let shieldCell = ConversationSecureSystemMessageSectionDescription()
            return [AnyConversationMessageCellDescription(shieldCell)]

        case .conversationIsVerified:
            let shieldCell = ConversationVerifiedSystemMessageSectionDescription()
            return [AnyConversationMessageCellDescription(shieldCell)]

        case .conversationIsDegraded:
            let shieldCell = ConversationDegradedSystemMessageSectionDescription()
            return [AnyConversationMessageCellDescription(shieldCell)]

        case .sessionReset:
            let sessionResetCell = ConversationSessionResetSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                sender: sender
            )
            return [AnyConversationMessageCellDescription(sessionResetCell)]

        case .decryptionFailed, .decryptionFailedResolved, .decryptionFailed_RemoteIdentityChanged:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                sender: sender,
                accentColor: accentColor
            )
            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .newClient:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(
                message: message,
                systemMessageData: systemMessageData,
                conversation: conversation,
                onUserTap: { userID in
                    showUser(id: userID, userSession: userSession)
                },
                onConversationTap: { conversationID in
                    showConversation(id: conversationID, userSession: userSession)
                }
            )
            return [AnyConversationMessageCellDescription(newClientCell)]

        case .ignoredClient:
            guard let user = systemMessageData.userTypes.first as? UserType else { fallthrough }
            let ignoredClientCell = ConversationIgnoredDeviceSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                user: user,
                onUserTap: { userID in
                    showUser(id: userID, userSession: userSession)
                }
            )
            return [AnyConversationMessageCellDescription(ignoredClientCell)]

        case .potentialGap:
            let missingMessagesCell = ConversationMissingMessagesSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )
            return [AnyConversationMessageCellDescription(missingMessagesCell)]

        case .participantsAdded, .participantsRemoved, .teamMemberLeave:
            let participantsChangedCell = ConversationParticipantsChangedSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )
            return [AnyConversationMessageCellDescription(participantsChangedCell)]

        case .readReceiptsEnabled,
             .readReceiptsDisabled,
             .readReceiptsOn:
            let cell = ConversationReadReceiptSettingChangedCellDescription(
                sender: sender,
                systemMessageType: systemMessageData.systemMessageType
            )
            return [AnyConversationMessageCellDescription(cell)]

        case .legalHoldEnabled, .legalHoldDisabled:
            let cell = ConversationLegalHoldCellDescription(
                systemMessageType: systemMessageData.systemMessageType,
                conversation: conversation as! ZMConversation
            )
            return [AnyConversationMessageCellDescription(cell)]

        case .newConversation:
            var cells: [AnyConversationMessageCellDescription] = []

            let welcomeCell = ConversationWelcomeSystemMessageCellDescription(
                variant: (
                    wireCells: conversation.isWireDriveEnabled,
                    isChannel: conversation.isChannel
                )
            )
            cells.append(AnyConversationMessageCellDescription(welcomeCell))

            let startedConversationCell = ConversationStartedSystemMessageCellDescription(message: message)
            cells.append(AnyConversationMessageCellDescription(startedConversationCell))

            // Only display invite user cell for team members
            if selfUser.isTeamMember,
               conversation.selfCanAddUsers(selfUser: selfUser),
               conversation.isOpenGroup {
                cells.append(
                    AnyConversationMessageCellDescription(
                        GuestsAllowedCellDescription(isChannel: conversation.isChannel)
                    )
                )
            }
            if conversation.isOpenGroup || conversation.isWireDriveEnabled {
                let encryptionInfoCell = ConversationEncryptionInfoSystemMessageCellDescription(
                    isWireDriveEnabled: conversation.isWireDriveEnabled
                )
                cells.append(AnyConversationMessageCellDescription(encryptionInfoCell))
            }

            if conversation.isWireDriveEnabled {
                let fileCollaborationCell = ConversationFileCollaborationSystemMessageCellDescription()
                cells.append(AnyConversationMessageCellDescription(fileCollaborationCell))

                let timerCell = ConversationMessageTimerSystemMessageCellDescription(
                    state: .unavailable
                )
                cells.append(AnyConversationMessageCellDescription(timerCell))
            }

            if conversation.isChannel, let channelHistoryDepth = conversation.channelHistoryDepth {
                let cell = ConversationChannelHistoryDepthSystemMessageCellDescription(
                    sender: sender,
                    historyDepth: channelHistoryDepth,
                    isNewConversation: true
                )

                cells.append(AnyConversationMessageCellDescription(cell))
            }

            return cells

        case .failedToAddParticipants:
            if let users = Array(systemMessageData.userTypes) as? [UserType], let buttonAction {

                let cellDescription = ConversationFailedToAddParticipantsSystemMessageCellDescription(
                    failedUsers: users,
                    isCollapsed: isCollapsed,
                    buttonAction: buttonAction
                )
                return [AnyConversationMessageCellDescription(cellDescription)]
            }

        case .domainsStoppedFederating:
            let domainsStoppedFederatingCell =
                ConversationDomainsStoppedFederatingSystemMessageCellDescription(systemMessageData: systemMessageData)
            return [AnyConversationMessageCellDescription(domainsStoppedFederatingCell)]

        case .mlsMigrationFinalized, .mlsMigrationJoinAfterwards, .mlsMigrationOngoingCall, .mlsMigrationStarted,
             .mlsMigrationUpdateVersion, .mlsMigrationPotentialGap:
            let description = MLSMigrationCellDescription(messageType: systemMessageData.systemMessageType)
            return [AnyConversationMessageCellDescription(description)]

        case .mlsNotSupportedSelfUser, .mlsNotSupportedOtherUser:
            if let user = conversation.connectedUserType {
                let description = MLSMigrationSupportCellDescription(
                    messageType: systemMessageData.systemMessageType,
                    for: user
                )
                return [AnyConversationMessageCellDescription(description)]
            } else {
                assertionFailure("connectedUserType should not be nil in this case")
            }

        case .unknownMessageContentTypeReceived:
            let unknownMessage = UnknownStoredMessageCellDescription()
            return [AnyConversationMessageCellDescription(unknownMessage)]

        case .invalid:
            // Nothing to display.
            WireLogger.conversation.warn("No cell to display for ZMSystemMessageType.invalid.")

        case .channelHistoryDepthModified:
            let cell = ConversationChannelHistoryDepthSystemMessageCellDescription(
                sender: sender,
                historyDepth: conversation.channelHistoryDepth,
                isNewConversation: false
            )
            return [AnyConversationMessageCellDescription(cell)]

        case .userRemovedFromTeam:
            let cell = UserRemovedFromTeamSystemMessageCellDescription()
            return [AnyConversationMessageCellDescription(cell)]
        }

        return []
    }

    private static func showUser(
        id: Any,
        userSession: UserSession
    ) {
        guard let managedId = id as? NSManagedObjectID,
              let zClientViewController = ZClientViewController.shared,
              let user = ZMUser.existingObject(with: managedId, inUserSession: userSession.contextProvider) else {
            return
        }
        zClientViewController.openClientListScreen(for: user)
    }

    private static func showConversation(
        id: Any,
        userSession: UserSession
    ) {
        guard let managedId = id as? NSManagedObjectID,
              let zClientViewController = ZClientViewController.shared,
              let conversation = ZMConversation.existingObject(
                  with: managedId,
                  inUserSession: userSession.contextProvider
              ) else {
            return
        }
        zClientViewController.openDetailScreen(for: conversation)
    }
}

private extension ConversationLike {
    var isOpenGroup: Bool {
        conversationType == .group && allowGuests
    }

    func selfCanAddUsers(selfUser: (any UserType)?) -> Bool {
        guard let user = selfUser else {
            assertionFailure("expected available 'user'!")
            return false
        }
        return user.canAddUser(to: self)
    }
}
