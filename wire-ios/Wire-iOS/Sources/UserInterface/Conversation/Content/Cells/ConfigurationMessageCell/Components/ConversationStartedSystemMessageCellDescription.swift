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
import WireDataModel
import WireDesign

final class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {

    typealias View = ConversationStartedSystemMessageCell<ConversationStartedSystemMessageCellDescription>
    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    var configuration: View.Configuration

    var message: ZMConversationMessage? {
        didSet {
            if let message {
                configuration.selectedUsers = Self.makeModel(message: message).selectedUsers
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin: CGFloat = 16
    var bottomMargin: CGFloat = -8

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var conversationObserverToken: Any?

    init(message: ZMConversationMessage) {
        self.configuration = Self.makeConfiguration(message: message)
        self.actionController = nil

        super.init()

        accessibilityLabel = configuration.message?.string
    }

    init(conversation: ZMConversation) {
        self.configuration = Self.makeConfiguration(from: conversation)
        self.actionController = nil

        super.init()

        accessibilityLabel = configuration.message?.string
    }

    private static func makeModel(message: ZMConversationMessage) -> ParticipantsCellViewModel {
        let color = LabelColors.textDefault
        let iconColor = IconColors.backgroundDefault
        return ParticipantsCellViewModel(
            font: .mediumFont,
            largeFont: .largeSemiboldFont,
            textColor: color,
            iconColor: iconColor,
            message: message
        )
    }

    private static func makeConfiguration(message: ZMConversationMessage) -> View.Configuration {
        let model = makeModel(message: message)
        return View.Configuration(
            title: model.attributedHeading(),
            message: model.attributedTitle(),
            selectedUsers: model.selectedUsers,
            icon: model.image()
        )
    }

    private static func makeConfiguration(from conversation: ZMConversation) -> View.Configuration {
        let font = UIFont.mediumFont
        let largeFont = UIFont.largeSemiboldFont
        let textColor = LabelColors.textDefault
        let iconColor = IconColors.backgroundDefault
        let isChannel = conversation.isChannel

        let creator: UserType = conversation.creator
        let senderName = creator.isSelfUser
            ? L10n.Localizable.Content.System.youNominative
            : (creator.name ?? L10n.Localizable.Conversation.Status.someone)

        // Heading (only for named conversations)
        let heading: NSAttributedString?
        if let name = conversation.displayName, !name.isEmpty {
            let headingText = isChannel
                ? (creator.isSelfUser
                    ? L10n.Localizable.Content.System.Channel.WithName.titleYou(senderName)
                    : L10n.Localizable.Content.System.Channel.WithName.title(senderName))
                : (creator.isSelfUser
                    ? L10n.Localizable.Content.System.Conversation.WithName.titleYou(senderName)
                    : L10n.Localizable.Content.System.Conversation.WithName.title(senderName))
            let text = headingText.attributedString && font
            let title = name.attributedString && largeFont
            heading = [text, title].joined(separator: "\n".attributedString) && textColor && .lineSpacing(4)
        } else {
            heading = nil
        }

        // Participants excluding creator, with self user placed last
        let creatorObjectID = conversation.creator.objectID
        let participantsExcludingCreator = conversation.sortedActiveParticipantsUserTypes.filter { participant in
            guard let zmUser = participant as? ZMUser else { return true }
            return zmUser.objectID != creatorObjectID
        }
        let hasSelf = !creator.isSelfUser && participantsExcludingCreator.contains(where: \.isSelfUser)
        var names = participantsExcludingCreator
            .filter { !$0.isSelfUser }
            .compactMap(\.name)
            .sorted()
        if hasSelf {
            names.append(L10n.Localizable.Content.System.youDative)
        }

        let participantsString = formatParticipantNames(names)

        // Title
        let message: NSAttributedString?
        if let name = conversation.displayName, !name.isEmpty {
            message = participantsString.isEmpty ? nil : "\(L10n.Localizable.Content.System.Conversation.WithName.participants) \(participantsString)" && font && textColor
        } else if creator.isSelfUser {
            message = L10n.Localizable.Content.System.Conversation.You.started(senderName, participantsString)
                && font && textColor
        } else {
            message = L10n.Localizable.Content.System.Conversation.Other.started(senderName, participantsString)
                && font && textColor
        }

        let icon = ConversationActionType.started(name: conversation.displayName).image(with: iconColor)

        return View.Configuration(title: heading, message: message, selectedUsers: [], icon: icon)
    }

    private static func formatParticipantNames(_ names: [String]) -> String {
        switch names.count {
        case 0: return ""
        case 1: return names[0]
        case 2: return L10n.Localizable.Content.System.participants1Other(names[0], names[1])
        default:
            let allButLast = names.dropLast().map { $0 + ", " }.joined()
            return allButLast + L10n.Localizable.Content.System.StartedConversation.truncatedPeople(names.last!)
        }
    }

}
