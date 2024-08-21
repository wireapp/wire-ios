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
import WireSyncEngine

final class ConversationNewDeviceSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationNewDeviceSystemMessageCell
    typealias LabelColors = SemanticColors.Label

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(
        message: ZMConversationMessage,
        systemMessageData: ZMSystemMessageData,
        conversation: ZMConversation
    ) {
        configuration = ConversationNewDeviceSystemMessageCellDescription.configuration(for: systemMessageData, in: conversation)
        accessibilityLabel = configuration.attributedText?.string
        actionController = nil
    }

    struct TextAttributes {
        let senderAttributes: [NSAttributedString.Key: AnyObject]
        let startedUsingAttributes: [NSAttributedString.Key: AnyObject]
        let linkAttributes: [NSAttributedString.Key: AnyObject]

        init(boldFont: UIFont, normalFont: UIFont, textColor: UIColor, link: URL) {
            senderAttributes = [.font: boldFont, .foregroundColor: textColor]
            startedUsingAttributes = [.font: normalFont, .foregroundColor: textColor]
            linkAttributes = [.font: normalFont, .link: link as AnyObject]
        }
    }

    private static func configuration(
        for systemMessage: ZMSystemMessageData,
        in conversation: ZMConversation
    ) -> View.Configuration {

        let textAttributes = TextAttributes(
            boldFont: .mediumSemiboldFont,
            normalFont: .mediumFont,
            textColor: LabelColors.textDefault,
            link: View.userClientURL
        )

        let clients = systemMessage.clients.compactMap({ $0 as? UserClientType })
        let users = systemMessage.userTypes
            .lazy
            .compactMap { $0 as? UserType }
            .sortedAscendingPrependingNil(by: \.name)

        if !systemMessage.addedUserTypes.isEmpty {
            return configureForAddedUsers(in: conversation, attributes: textAttributes)
        } else if users.count == 1, let user = users.first, user.isSelfUser {
            return configureForNewClientOfSelfUser(user, clients: clients, link: View.userClientURL)
        } else {
            return configureForOtherUsers(users, conversation: conversation, clients: clients, attributes: textAttributes)
        }
    }

    private static var verifiedIcon: UIImage {
        return WireStyleKit.imageOfShieldnotverified
    }

    private static func configureForNewClientOfSelfUser(_ selfUser: UserType, clients: [UserClientType], link: URL) -> View.Configuration {
        let string = L10n.Localizable.Content.System.selfUserNewClient(link.absoluteString)
        let attributedText = NSMutableAttributedString.markdown(from: string, style: .systemMessage)
        let selfUserClient = SessionManager.shared?.activeUserSession?.selfUserClient
        let isSelfClient = clients.first?.isEqual(selfUserClient) ?? false
        return View.Configuration(attributedText: attributedText, icon: isSelfClient ? nil : verifiedIcon, linkTarget: .user(selfUser))
    }

    private static func configureForOtherUsers(
        _ users: [UserType],
        conversation: ZMConversation,
        clients: [UserClientType],
        attributes: TextAttributes
    ) -> View.Configuration {

        let displayNamesOfOthers = users.filter { !$0.isSelfUser }.compactMap { $0.name }
        let firstTwoNames = displayNamesOfOthers.prefix(2)
        let senderNames = firstTwoNames.joined(separator: ", ")
        let additionalSenderCount = max(displayNamesOfOthers.count - 1, 1)

        // %@ %#@d_number_of_others@ started using %#@d_new_devices@
        let senderNamesString = L10n.Localizable.Content.System.peopleStartedUsing(senderNames, additionalSenderCount, clients.count)

        let userClientString = L10n.Localizable.Content.System.newDevices(clients.count)

        var attributedSenderNames = NSAttributedString(string: senderNamesString, attributes: attributes.startedUsingAttributes)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.senderAttributes, toSubstring: senderNames)
        attributedSenderNames = attributedSenderNames.setAttributes(attributes.linkAttributes, toSubstring: userClientString)
        let attributedText = attributedSenderNames

        var linkTarget: View.LinkTarget
        if let user = users.first, users.count == 1 {
            linkTarget = .user(user)
        } else {
            linkTarget = .conversation(conversation)
        }

        return View.Configuration(attributedText: attributedText, icon: verifiedIcon, linkTarget: linkTarget)
    }

    private static func configureForAddedUsers(in conversation: ZMConversation, attributes: TextAttributes) -> View.Configuration {
        let attributedNewUsers = NSAttributedString(string: L10n.Localizable.Content.System.newUsers, attributes: attributes.startedUsingAttributes)

        let attributedLink = NSAttributedString(string: L10n.Localizable.Content.System.verifyDevices, attributes: attributes.linkAttributes)
        let attributedText = attributedNewUsers + " " + attributedLink

        return View.Configuration(attributedText: attributedText, icon: verifiedIcon, linkTarget: .conversation(conversation))
    }

}
