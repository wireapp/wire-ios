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

final class ConversationCannotDecryptSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType) {
        let icon: UIImage =
            if data.systemMessageType == .decryptionFailedResolved {
                StyleKitIcon.checkmark.makeImage(
                    size: 16,
                    color: IconColors.foregroundCheckMarkInSystemMessage
                )
            } else {
                StyleKitIcon.exclamationMark.makeImage(
                    size: 16,
                    color: IconColors.foregroundExclamationMarkInSystemMessage
                )
            }

        let title = ConversationCannotDecryptSystemMessageCellDescription.makeAttributedString(
            systemMessage: data,
            sender: sender
        )

        self.configuration = View.Configuration(
            icon: icon,
            attributedText: title,
            showLine: false
        )

        self.accessibilityLabel = title.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationCannotDecryptSystemMessageCell
    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

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

    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherDescription = other as? ConversationCannotDecryptSystemMessageCellDescription else {
            return false
        }

        return configuration.attributedText == otherDescription.configuration.attributedText
    }

    // MARK: Private

    private static let resetSessionURL = URL(string: "action://reset-session")!

    // MARK: - Localization

    private static let BaseLocalizationString = "content.system.cannot_decrypt"

    private static func makeAttributedString(
        systemMessage: ZMSystemMessageData,
        sender: UserType
    ) -> NSAttributedString {
        let messageString = messageString(systemMessage.systemMessageType, sender: sender)
        let resetSessionString = resetSessionString()
        let errorDetailsString = errorDetailsString(
            errorCode: systemMessage.decryptionErrorCode?.intValue ?? 0,
            clientIdentifier: systemMessage.senderClientID ?? "N/A"
        )

        var components: [NSAttributedString]

        switch systemMessage.systemMessageType {
        case .decryptionFailed:
            components = [messageString]

            if systemMessage.isDecryptionErrorRecoverable {
                components.append(resetSessionString)
            }

        case .decryptionFailedResolved:
            components = [
                messageString,
                errorDetailsString,
            ]

        case .decryptionFailed_RemoteIdentityChanged:
            components = [
                messageString,
            ]

        default:
            fatal("Incorrect cell configuration")
        }

        return components.joined(separator: NSAttributedString(string: "\n"))
    }

    private static func localizationKey(_ systemMessageType: ZMSystemMessageType) -> String {
        let localizationKey: String
        switch systemMessageType {
        case .decryptionFailed:
            localizationKey = BaseLocalizationString
        case .decryptionFailedResolved:
            localizationKey = BaseLocalizationString + "_resolved"
        case .decryptionFailed_RemoteIdentityChanged:
            localizationKey = BaseLocalizationString + "_identity_changed"
        default:
            fatal("Incorrect cell configuration")
        }

        return localizationKey
    }

    private static func messageString(
        _ systemMessageType: ZMSystemMessageType,
        sender: UserType
    ) -> NSAttributedString {
        let name = sender.name ?? ""
        var localizationKey = localizationKey(systemMessageType)

        if sender.isSelfUser {
            localizationKey += ".self"
        } else {
            localizationKey += ".other"
        }

        return NSMutableAttributedString.markdown(from: localizationKey.localized(args: name), style: .systemMessage)
    }

    private static func resetSessionString() -> NSAttributedString {
        let string = L10n.Localizable.Content.System.CannotDecrypt.resetSession

        return NSAttributedString(
            string: string.localizedUppercase,
            attributes: [
                .link: resetSessionURL,
                .foregroundColor: UIColor.accent(),
                .font: UIFont.mediumSemiboldFont,
            ]
        )
    }

    private static func errorDetailsString(errorCode: Int, clientIdentifier: String) -> NSAttributedString {
        let string = L10n.Localizable.Content.System.CannotDecrypt.errorDetails(errorCode, clientIdentifier)

        return NSAttributedString(
            string: string.localizedUppercase,
            attributes: [
                .foregroundColor: LabelColors.textDefault,
                .font: UIFont.mediumFont,
            ]
        )
    }
}
