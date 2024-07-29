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

final class MLSMigrationCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell
    typealias SystemMessageMLSMigrationLocalizable = L10n.Localizable.Content.System.MlsMigration

    private static let linkAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumSemiboldFont,
        .link: WireURLs.shared.mlsInfo
    ]

    let configuration: View.Configuration

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    weak var message: WireDataModel.ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    init(messageType: ZMSystemMessageType) {
        let icon = UIImage(resource: .attention).withTintColor(SemanticColors.Icon.backgroundDefault)
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
        case .mlsMigrationPotentialGap:
            return makePotentialGapAttributedString()
        default:
            assertionFailure("MLSMigrationCellDescription requires ZMSystemMessageType of MLS, but found \(messageType)!")
            return nil
        }
    }

    private static func makeFinalizedAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.Finalized.done,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocalizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeStartedAttributedString() -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.Started.description,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocalizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeOngoingCallAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.ongoingCall,
            style: .systemMessage
        )
    }

    private static func makeUpdateVersionAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.Started.updateLatestVersion,
            style: .systemMessage
        )
    }

    private static func makeJoinAfterwardsAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.joinAfterwards,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocalizable.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makePotentialGapAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocalizable.potentialGap,
            style: .systemMessage
        )

        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocalizable.learnMore,
            attributes: linkAttributes
        )

        return [text, link].joined(separator: NSAttributedString(" "))

    }

}
