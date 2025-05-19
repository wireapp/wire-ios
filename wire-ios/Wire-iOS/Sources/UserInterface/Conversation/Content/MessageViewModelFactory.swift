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

import Foundation
import WireConversationUI
import WireDataModel
import WireSyncEngine
import WireReusableUIComponents
import WireFoundation

struct MessageViewModelFactoryImpl: MessageViewModelFactory {

    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func makeTextMessageViewModel(
        message: ConversationMessage,
        selfUser: any UserType,
        accentColor: AccentColor,
        shouldShowSender: Bool,
        shouldShowStatus: Bool
    ) -> TextMessageViewModel {
        let context = userSession.contextProvider.viewContext
        let messagedObjectID = message.objectId

        var senderViewModelWrapper: MessageSenderViewModelWrapper? = .init(state: .none)
        if shouldShowSender, let sender = message.senderUser {
            senderViewModelWrapper = MessageSenderViewModelWrapper.init(state: .some(
                MessageSenderViewModel(
                    avatarViewModel: AvatarViewModel(
                        color: accentColor.color
                    ),
                    senderModel: sender.toUIModel(),
                    isDeleted: message.isDeletion,
                    teamRoleIndicator: sender.teamRoleIndicator(selfUser: selfUser),
                    authorChanged: SenderObserver(
                        messageID: messagedObjectID,
                        viewContext: context
                    )
                )
            ))
        }
        
        let statusViewModel = if shouldShowStatus {
            MessageStatusViewModel(
                messageModel: message.toUIModel(),
                statusObserver: StatusObserver(
                    messageID: messagedObjectID,
                    viewContext: context
                )
            )
        } else {
            MessageStatusViewModel.none()
        }
        
        return TextMessageViewModel(
            text: message.textMessageData?.messageText ?? "",
            accentColor: accentColor,
            isObfuscated: message.isObfuscated,
            senderViewModelWrapper: senderViewModelWrapper,
            statusViewModel: statusViewModel
        )
    }
}

extension UserType {
    func toUIModel() -> UserModel {
        UserModel(
            name: name,
            isSelfUser: true,
            isServiceUser: isServiceUser,
            accentColor: accentColor
        )
    }
}

extension UserType {

    func teamRoleIndicator(selfUser: any UserType) -> TeamRoleIndicator? {
        if isServiceUser {
            .service

        } else if isExternalPartner {
            .externalPartner

        } else if isFederated {
            .federated

        } else if !isTeamMember, selfUser.isTeamMember {
            .guest
        } else {
            nil
        }
    }

}

extension ZMConversationMessage {
    func toUIModel() -> MessageModel {
        .init(
            nonce: nonce,
            sender: senderUser?.toUIModel(),
            systemMessageType: systemMessageData?.systemMessageType.toUIModel(),
            updatedAt: updatedAt,
            receivedAt: serverTimestamp,
            expirationReason: (self as? SwiftConversationMessage)?.expirationReason?.toUIModel(),
            conversationType: conversationLike?.conversationType.toUIModel(),
            readReceiptsCount: readReceipts.count,
            deliveryState: deliveryState.toUIModel(),
            isSent: isSent
        )
    }
}

extension ZMMessage {
    func toUIModel() -> MessageModel {
        .init(
            nonce: nonce,
            sender: sender?.toUIModel(),
            systemMessageType: systemMessageData?.systemMessageType.toUIModel(),
            updatedAt: updatedAt,
            receivedAt: serverTimestamp,
            expirationReason: expirationReason?.toUIModel(),
            conversationType: conversation?.conversationType.toUIModel(),
            readReceiptsCount: readReceipts.count,
            deliveryState: deliveryState.toUIModel(),
            isSent: isSent
        )
    }
}

extension ZMDeliveryState {
    func toUIModel() -> DeliveryStateModel {
        switch self {
        case .invalid:
            .invalid
        case .pending:
            .pending
        case .sent:
            .sent
        case .delivered:
            .delivered
        case .read:
            .read
        case .failedToSend:
            .failedToSend
        }
    }
}

extension ZMSystemMessageType {
    func toUIModel() -> SystemMessageTypeModel? {
        .init(rawValue: Int(rawValue))
    }
}

extension ExpirationReason {
    func toUIModel() -> ExpirationReasonModel? {
        .init(rawValue: Int(rawValue))
    }
}

extension ZMConversationType {
    func toUIModel() -> ConversationTypeModel? {
        switch self {
        case .invalid:
            return nil
        case .`self`:
            return .`self`
        case .group:
            return .group
        case .oneOnOne:
            return .oneOnOne
        case .connection:
            return .connection
        }
    }
}
