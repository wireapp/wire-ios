//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - ConversationSystemMessageCellDescription

enum ConversationSystemMessageCellDescription {
    static func cells(
        for message: ZMConversationMessage,
        isCollapsed: Bool = true,
        buttonAction: Completion? = nil
    ) -> [AnyConversationMessageCellDescription] {
        guard let systemMessageData = message.systemMessageData,
              let sender = message.senderUser,
              let conversation = message.conversationLike
        else {
            preconditionFailure("Invalid system message")
        }

        switch systemMessageData.systemMessageType {
        case .connectionRequest,
             .connectionUpdate,
             .reactivatedDevice,
             .usingNewDevice:
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
                message: message,
                timestamp: nil
            )

            return [AnyConversationMessageCellDescription(senderCell)]

        case .messageTimerUpdate:
            guard let timer = systemMessageData.messageTimer else {
                fallthrough
            }

            let timerCell = ConversationMessageTimerSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                timer: timer,
                sender: sender
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

        case .decryptionFailed,
             .decryptionFailed_RemoteIdentityChanged,
             .decryptionFailedResolved:
            let decryptionCell = ConversationCannotDecryptSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                sender: sender
            )

            return [AnyConversationMessageCellDescription(decryptionCell)]

        case .newClient:
            let newClientCell = ConversationNewDeviceSystemMessageCellDescription(
                message: message,
                systemMessageData: systemMessageData,
                conversation: conversation as! ZMConversation
            )

            return [AnyConversationMessageCellDescription(newClientCell)]

        case .ignoredClient:
            guard let user = systemMessageData.userTypes.first as? UserType else {
                fallthrough
            }
            let ignoredClientCell = ConversationIgnoredDeviceSystemMessageCellDescription(
                message: message,
                data: systemMessageData,
                user: user
            )

            return [AnyConversationMessageCellDescription(ignoredClientCell)]

        case .potentialGap:
            let missingMessagesCell = ConversationMissingMessagesSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )

            return [AnyConversationMessageCellDescription(missingMessagesCell)]

        case .participantsAdded,
             .participantsRemoved,
             .teamMemberLeave:
            let participantsChangedCell = ConversationParticipantsChangedSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )

            return [AnyConversationMessageCellDescription(participantsChangedCell)]

        case .readReceiptsDisabled,
             .readReceiptsEnabled,
             .readReceiptsOn:
            let cell = ConversationReadReceiptSettingChangedCellDescription(
                sender: sender,
                systemMessageType: systemMessageData.systemMessageType
            )

            return [AnyConversationMessageCellDescription(cell)]

        case .legalHoldDisabled,
             .legalHoldEnabled:
            let cell = ConversationLegalHoldCellDescription(
                systemMessageType: systemMessageData.systemMessageType,
                conversation: conversation as! ZMConversation
            )

            return [AnyConversationMessageCellDescription(cell)]

        case .newConversation:
            var cells: [AnyConversationMessageCellDescription] = []
            let startedConversationCell = ConversationStartedSystemMessageCellDescription(
                message: message,
                data: systemMessageData
            )
            cells.append(AnyConversationMessageCellDescription(startedConversationCell))

            // Only display invite user cell for team members
            if let user = SelfUser.provider?.providedSelfUser,
               user.isTeamMember,
               conversation.selfCanAddUsers,
               conversation.isOpenGroup {
                cells.append(AnyConversationMessageCellDescription(GuestsAllowedCellDescription()))
            }
            if conversation.isOpenGroup {
                let encryptionInfoCell = ConversationEncryptionInfoSystemMessageCellDescription()
                cells.append(AnyConversationMessageCellDescription(encryptionInfoCell))
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

        case .mlsMigrationFinalized,
             .mlsMigrationJoinAfterwards,
             .mlsMigrationOngoingCall,
             .mlsMigrationPotentialGap,
             .mlsMigrationStarted,
             .mlsMigrationUpdateVersion:
            let description = MLSMigrationCellDescription(messageType: systemMessageData.systemMessageType)
            return [AnyConversationMessageCellDescription(description)]

        case .mlsNotSupportedOtherUser,
             .mlsNotSupportedSelfUser:
            if let user = conversation.connectedUserType {
                let description = MLSMigrationSupportCellDescription(
                    messageType: systemMessageData.systemMessageType,
                    for: user
                )
                return [AnyConversationMessageCellDescription(description)]
            } else {
                assertionFailure("connectedUserType should not be nil in this case")
            }

        case .invalid:
            let unknownMessage = UnknownMessageCellDescription()
            return [AnyConversationMessageCellDescription(unknownMessage)]
        }

        return []
    }
}

extension ConversationLike {
    fileprivate var isOpenGroup: Bool {
        conversationType == .group && allowGuests
    }

    fileprivate var selfCanAddUsers: Bool {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return false
        }
        return user.canAddUser(to: self)
    }
}
