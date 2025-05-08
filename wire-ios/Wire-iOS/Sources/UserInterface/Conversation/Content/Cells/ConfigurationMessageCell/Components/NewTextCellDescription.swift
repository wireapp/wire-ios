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

import UIKit
import WireConversationUI
import WireFoundation
import WireSystem
import WireDataModel

protocol NewCellDescription { }
extension NewTextCellDescription: NewCellDescription { }
extension BurstTimestampSenderMessageCellDescription: NewCellDescription { }

final class NewTextCellDescription: ConversationMessageCellDescription {
    
    typealias View = NewTextCell

    @MainActor var conversationCellModel: ConversationCellModel?

    func makeConversationCellModel() -> ConversationCellModel {
        let model = TextMessageViewModel(
            text: configuration.text,
            senderViewModel: MessageSenderViewModel(
                avatar: AvatarViewModel(color: configuration.accentColor.color),
                author: AttributedString(configuration.author)
            ),
            statusViewModel: MessageStatusViewModel(
                deliveryState: message?.deliveryState.toUIModel(),
                edited: message?.updatedAt != nil,
                timestamp: message?.serverTimestamp?.formattedDate ?? "-"
            )
        )
        return ConversationCellModel.text(model)
    }

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin = CGFloat()
    var bottomMargin = CGFloat()

    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    
    init(
        configuration: View.Configuration
    ) {
        self.configuration = configuration
        self.conversationCellModel = makeConversationCellModel()
    }

    convenience init(
        message: ZMConversationMessage,
        context: ConversationMessageContext,
        accentColor: UIColor
    ) {
        let configuration = View.Configuration(
            text: message.textMessageData?.messageText ?? "",
            author: message.senderName,
            accentColor: accentColor
        )
        self.init(configuration: configuration)
    }

}

final class NewTextCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {
        let text: String
        let author: String
        let accentColor: UIColor
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {}

}

extension ZMDeliveryState {
    func toUIModel() -> DeliveryState {
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
