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
    typealias SystemMessageMLSMigrationLocale = L10n.Localizable.Content.System.MlsMigration

    private static let linkAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumSemiboldFont,
        .link: URL.wr_mlsLearnMore
    ]

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
        case .mlsMigrationMLSNotSupportedSelfUser:
            return makeMLSNotSupportedForSelfUser(username: user.name ?? "")
        case .mlsMigrationMLSNotSupportedOtherUser:
            return makeMLSNotSupportedForOtherUser(username: user.name ?? "")
        default:
            assertionFailure("MLSMigrationCellDescription requires ZMSystemMessageType of MLS, but found \(messageType)!")
            return nil
        }
    }

    private static func makeFinalizedAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.Finalized.done,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocale.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeStartedAttributedString() -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.Started.description,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocale.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeOngoingCallAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.ongoingCall,
            style: .systemMessage
        )
    }

    private static func makeUpdateVersionAttributedString() -> NSAttributedString? {
        NSAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.Started.updateLatestVersion,
            style: .systemMessage
        )
    }

    private static func makeJoinAfterwardsAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.joinAfterwards,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocale.learnMore,
            attributes: linkAttributes
        )
        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makePotentialGapAttributedString() -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.potentialGap,
            style: .systemMessage
        )

        let link = NSAttributedString(
            string: SystemMessageMLSMigrationLocale.learnMore,
            attributes: linkAttributes
        )

        return [text, link].joined(separator: NSAttributedString(" "))

    }

    private static func makeMLSNotSupportedForSelfUser(username: String) -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.mlsNotSupportedByYou(username),
            style: .systemMessage
        )

        let link = NSMutableAttributedString(
            string: SystemMessageMLSMigrationLocale.Download.Mls.wire,
            attributes: linkAttributesForDownloadingWire
        )

        return [text, link].joined(separator: NSAttributedString(" "))
    }

    private static func makeMLSNotSupportedForOtherUser(username: String) -> NSAttributedString? {

        let text = NSMutableAttributedString.markdown(
            from: SystemMessageMLSMigrationLocale.mlsNotSupportedByOtherUser(username, username),
            style: .systemMessage
        )

        return text

    }

}
