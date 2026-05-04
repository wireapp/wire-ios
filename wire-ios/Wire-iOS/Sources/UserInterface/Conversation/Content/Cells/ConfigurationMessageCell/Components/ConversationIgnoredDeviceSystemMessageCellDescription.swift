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
import WireCommonComponents
import WireDataModel
import WireDesign

final class ConversationIgnoredDeviceSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationNewDeviceSystemMessageCell<ConversationIgnoredDeviceSystemMessageCellDescription>
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(
        message: ZMConversationMessage,
        data: ZMSystemMessageData,
        user: UserType,
        onUserTap: @escaping (_ userID: Any) -> Void
    ) {

        let title = ConversationIgnoredDeviceSystemMessageCellDescription.makeAttributedString(
            systemMessage: data,
            user: user
        )

        self.configuration = View.Configuration(
            attributedText: title,
            icon: WireStyleKit.imageOfShieldnotverified,
            linkTarget: .user(user.objectId, onUserTap)
        )

        self.accessibilityLabel = configuration.attributedText?.string
        self.actionController = nil
    }

    private static func makeAttributedString(
        systemMessage: ZMSystemMessageData,
        user: UserType
    ) -> NSAttributedString {

        typealias SystemMessageLocale = L10n.Localizable.Content.System
        let string: String
        let link = View.userClientURL.absoluteString

        if user.isSelfUser == true {
            string = SystemMessageLocale.unverifiedSelfDevices(link)
        } else {
            string = SystemMessageLocale.unverifiedOtherDevices(user.name ?? "", link)
        }

        return .markdown(from: string, style: .systemMessage)
    }

}
