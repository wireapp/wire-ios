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

import Foundation
import WireDataModel

final class MLSMigrationSupportCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell
    typealias SystemMessageMLSMigrationLocalizable = L10n.Localizable.Content.System.MlsMigration

    private static let linkAttributesForDownloadingWire: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumSemiboldFont,
        .link: URL.wr_wireAppOnItunes
    ]

    let configuration: View.Configuration

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    var message: WireDataModel.ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    init(messageType: ZMSystemMessageType, for user: UserType) {
        let icon = Asset.Images.attention.image.withTintColor(SemanticColors.Icon.backgroundDefault)
        let content = Self.makeAttributedString(messageType: messageType, for: user)

        configuration = View.Configuration(icon: icon, attributedText: content, showLine: false)
        accessibilityLabel = content?.string
    }

    // MARK: Attributed Strings

    private static func makeAttributedString(messageType: ZMSystemMessageType, for user: UserType) -> NSAttributedString? {
        switch messageType {
        case .mlsNotSupportedSelfUser:
            return makeMLSNotSupportedForSelfUser(username: user.name ?? "")
        case .mlsNotSupportedOtherUser:
            return makeMLSNotSupportedForOtherUser(username: user.name ?? "")
        default:
            assertionFailure("MLSMigrationCellDescription requires ZMSystemMessageType of MLS, but found \(messageType)!")
            return nil
        }
    }

    private static func makeMLSNotSupportedForSelfUser(username: String) -> NSAttributedString? {
        let baseMessage = SystemMessageMLSMigrationLocalizable.mlsNotSupportedByYou(username)

        let attributedMessage = NSAttributedString.markdown(from: baseMessage, style: .systemMessage)

        let linkText = SystemMessageMLSMigrationLocalizable.Download.Mls.wire

        if let linkRange = attributedMessage.string.range(of: linkText) {
            let nsLinkRange = NSRange(linkRange, in: attributedMessage.string)

            let mutableAttributedMessage = NSMutableAttributedString(attributedString: attributedMessage)

            mutableAttributedMessage.addAttributes(linkAttributesForDownloadingWire, range: nsLinkRange)

            return mutableAttributedMessage
        }

        return attributedMessage
    }

    private static func makeMLSNotSupportedForOtherUser(username: String) -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.mlsNotSupportedByOtherUser(username, username),
            style: .systemMessage
        )

        return text

    }

}
