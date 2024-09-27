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
import WireCommonComponents
import WireDataModel
import WireDesign

final class ConversationIgnoredDeviceSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(
        message: ZMConversationMessage,
        data: ZMSystemMessageData,
        user: UserType
    ) {
        let title = ConversationIgnoredDeviceSystemMessageCellDescription.makeAttributedString(
            systemMessage: data,
            user: user
        )

        self.configuration = View.Configuration(
            attributedText: title,
            icon: WireStyleKit.imageOfShieldnotverified,
            linkTarget: .user(user)
        )

        self.accessibilityLabel = configuration.attributedText?.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationNewDeviceSystemMessageCell

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    // MARK: Private

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
