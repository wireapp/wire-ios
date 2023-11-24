//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class MLSMigrationCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell

    private static let linkAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumSemiboldFont,
        .underlineStyle: NSUnderlineStyle(.single).rawValue as NSNumber
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

    init(messageType: ZMSystemMessageType) {
        let icon = Asset.Images.attention.image.withTintColor(SemanticColors.Icon.backgroundDefault)
        let content = Self.makeAttributedString(messageType: messageType)

        configuration = View.Configuration(icon: icon, attributedText: content, showLine: false)
        accessibilityLabel = content?.string
    }

    // MARK: Attributed Strings

    private static func makeAttributedString(messageType: ZMSystemMessageType) -> NSAttributedString? {
        switch messageType {
        case .mlsMigrationFinalized:
            return makeFinalizedAttributedString()
        case .mlsMigrationStarted:
            return makeStartedAttributedString()
        case .mlsMigrationOngoingCall:
            return makeOngoingCallAttributedString()
        case .mlsMigrationUpdateVersion:
            return makeUpdateVersionAttributedString()
        case .mlsMigrationJoinAfterwards:
            return makeJoinAfterwardsAttributedString()
        default:
            assertionFailure("MLSMigrationCellDescription requires ZMSystemMessageType of MLS, but found \(messageType)!")
            return nil
        }
    }

    private static func makeFinalizedAttributedString() -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: Localizable.Finalized.done,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: Localizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeStartedAttributedString() -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: Localizable.Started.description,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: Localizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeOngoingCallAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: L10n.Localizable.Content.System.MlsMigration.ongoingCall,
            style: .systemMessage
        )
    }

    private static func makeUpdateVersionAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: L10n.Localizable.Content.System.MlsMigration.Started.updateLatestVersion,
            style: .systemMessage
        )
    }

    private static func makeJoinAfterwardsAttributedString() -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: Localizable.joinAfterwards,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: Localizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }
}
