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
import WireMessagingDomain
import WireUtilities

final class ConversationSharedDriveSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias WireDriveSelfUserRole = WireDriveParticipant.Role

    // MARK: Properties

    typealias View = ConversationSystemMessageCell<ConversationSharedDriveSystemMessageCellDescription>
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    // MARK: initialization

    init(selfUserRole: WireDriveSelfUserRole) {
        let icon = UIImage(systemName: "rectangle.stack.fill")?
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(ColorTheme.Base.secondaryText)

        let title = Self.makeTitle(selfUserRole: selfUserRole)

        self.configuration = View.Configuration(
            icon: icon,
            attributedText: title,
            showLine: false,
            resetLinkStyleForOverride: true
        )

        self.actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

    private static func makeTitle(selfUserRole: WireDriveSelfUserRole) -> NSAttributedString {
        typealias FileCollaboration = L10n.Localizable.Content.System.FileCollaboration

        let driveAccessTitle = selfUserRole == .editor ? FileCollaboration.Enabled
            .editorAccess : FileCollaboration.Enabled.viewerAccess
        let spacer = " "
        // TODO: [WPB-25941] Remove developer flag when feature is complete
        let driveAccessText = DeveloperFlag.enableDrivePermissions.isOn ? ".\(spacer + driveAccessTitle)" : ""
        let enabledText = FileCollaboration.SharedDriveState.enabled
        let fullText = L10n.Localizable.Content.System.FileCollaboration.sharedDriveState(enabledText) + driveAccessText
        var attributedText: NSMutableAttributedString
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: UIFont.mediumFont,
            .foregroundColor: ColorTheme.Backgrounds.onSurface
        ]

        attributedText = .init(
            string: fullText,
            attributes: baseAttributes
        )

        if let range = fullText.range(of: enabledText, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: fullText)
            attributedText.addAttribute(.font, value: UIFont.mediumSemiboldFont, range: nsRange)
        }

        // TODO: [WPB-25941] Remove developer flag when feature is complete
        if DeveloperFlag.enableDrivePermissions.isOn {
            let learnMoreLabel = FileCollaboration.Enabled.learnMore
            let linkUrl = WireURLs.shared.learnMoreAboutDrivePermissions
            let linkAttributes: [NSAttributedString.Key: AnyObject] = [
                .font: UIFont.mediumSemiboldFont,
                .foregroundColor: ColorTheme.Backgrounds.onSurface,
                .link: linkUrl as AnyObject,
                .underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject,
                .underlineColor: ColorTheme.Backgrounds.onSurface
            ]

            let spaceBetweenParagraphs = "\n\n"
            attributedText.append(.init(string: spaceBetweenParagraphs + learnMoreLabel, attributes: linkAttributes))
        }

        return attributedText
    }

}
