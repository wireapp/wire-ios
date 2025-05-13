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

struct MessageViewModelFactoryImpl: MessageViewModelFactory {
    
    private let userSession: UserSession
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func makeTextMessageViewModel(
        message: ZMMessage,
        selfUser: any UserType,
        accentColor: UIColor
    ) -> TextMessageViewModel {
        var senderViewModel: MessageSenderViewModel? = nil
        if let sender = message.sender {
            senderViewModel = MessageSenderViewModel(
                avatar: AvatarViewModel(
                    color: accentColor.color
                ),
                senderModel: sender.toUIModel(),
                isDeleted: message.isDeletion,
                teamRoleIndicator: sender.teamRoleIndicator(selfUser: selfUser),
                authorChanged: SenderObserver(
                    messageID: message.objectID,
                    viewContext: userSession.contextProvider.viewContext
                )
            )
        }
        return TextMessageViewModel(
            text: message.textMessageData?.messageText ?? "",
            senderViewModel: senderViewModel,
            statusViewModel: MessageStatusViewModel(
                deliveryState: message.deliveryState.toUIModel(),
                edited: message.updatedAt != nil,
                timestamp: message.serverTimestamp?.formattedDate ?? "-"
            )
        )
    }
}

extension UserType {
    func toUIModel() -> UserModel {
        UserModel(
            name: name,
            isServiceUser: isServiceUser,
            accentColor: accentColor)
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
