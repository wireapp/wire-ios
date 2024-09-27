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
import WireDesign

final class MLSMigrationSupportCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(messageType: ZMSystemMessageType, for user: UserType) {
        let icon = UIImage(resource: .attention).withTintColor(SemanticColors.Icon.backgroundDefault)
        let content = Self.makeAttributedString(messageType: messageType, for: user)

        self.configuration = View.Configuration(icon: icon, attributedText: content, showLine: false)
        self.accessibilityLabel = content?.string
    }

    // MARK: Internal

    typealias View = ConversationSystemMessageCell
    typealias SystemMessageMLSMigrationLocalizable = L10n.Localizable.Content.System.MlsMigration

    let configuration: View.Configuration

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    var message: WireDataModel.ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    // MARK: Private

    // MARK: Attributed Strings

    private static func makeAttributedString(
        messageType: ZMSystemMessageType,
        for user: UserType
    ) -> NSAttributedString? {
        switch messageType {
        case .mlsNotSupportedSelfUser:
            return makeMLSNotSupportedMessageForSelfUser(username: user.name ?? "")
        case .mlsNotSupportedOtherUser:
            return makeMLSNotSupportedMessageForOtherUser(username: user.name ?? "")
        default:
            assertionFailure(
                "MLSMigrationCellDescription requires ZMSystemMessageType of MLS, but found \(messageType)!"
            )
            return nil
        }
    }

    private static func makeMLSNotSupportedMessageForSelfUser(username: String) -> NSAttributedString? {
        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.mlsNotSupportedByYou(
                username,
                WireURLs.shared.appOnItunes.absoluteString
            ),
            style: .systemMessage
        )

        return text
    }

    private static func makeMLSNotSupportedMessageForOtherUser(username: String) -> NSAttributedString? {
        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.mlsNotSupportedByOtherUser(username, username),
            style: .systemMessage
        )

        return text
    }
}
