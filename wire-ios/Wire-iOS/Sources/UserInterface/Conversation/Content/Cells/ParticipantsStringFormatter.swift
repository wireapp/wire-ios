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

private typealias Attributes = [NSAttributedString.Key: AnyObject]

extension ConversationActionType {
    fileprivate func formatKey(senderIsSelfUser: Bool) -> String {
        switch self {
        case .left: localizationKey(with: "left", senderIsSelfUser: senderIsSelfUser)

        case .added(herself: true): "content.system.conversation.guest.joined"

        case .added(herself: false): localizationKey(with: "added", senderIsSelfUser: senderIsSelfUser)

        case .removed(reason: .legalHoldPolicyConflict): localizationKey(
                with: "removed",
                senderIsSelfUser: senderIsSelfUser
            ) +
                ".legalhold"

        case .removed: localizationKey(with: "removed", senderIsSelfUser: senderIsSelfUser)

        case .none,
             .started(withName: .none): localizationKey(with: "started", senderIsSelfUser: senderIsSelfUser)

        case .started(withName: .some): "content.system.conversation.with_name.participants"

        case .teamMemberLeave: "content.system.conversation.team.member-leave"
        }
    }

    private func localizationKey(with pathComponent: String, senderIsSelfUser: Bool) -> String {
        let senderPath = senderIsSelfUser ? "you" : "other"
        return "content.system.conversation.\(senderPath).\(pathComponent)"
    }
}

// MARK: - FormatSequence

/// This class assists in applying string attributes to localized strings.
/// The issue with localized strings is that you can not pass attributed
/// strings as arguments to format strings, therefore the styling must take
/// place after localization. This is especially difficult when the argument
/// requires multiple attributes in various parts of the string. This data
/// structure keeps track of which string components should be applied with
/// which attributes. Then, given an attributed string, these attributes are
/// applied to their corresponding component.
private final class FormatSequence {
    typealias SubstringAttrs = (substring: String, attrs: Attributes)

    var string = String()
    var componentAttributes = [SubstringAttrs]()

    /// Append a component string with the given attributes.
    func append(_ component: String, with attrs: Attributes) {
        string.append(component)
        define(attrs, forComponent: component)
    }

    /// Define the attribute to be applied for the given substring.
    func define(_ attrs: Attributes, forComponent string: String) {
        componentAttributes.append(SubstringAttrs(string, attrs))
    }

    /// Apply all attributes for their corresponding components to the given
    /// attributed string.
    func applyComponentAttributes(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutableCopy = NSMutableAttributedString(attributedString: attributedString)
        componentAttributes.forEach { mutableCopy.addAttributes($0.attrs, to: $0.substring) }
        return mutableCopy
    }
}

// MARK: - ParticipantsStringFormatter

final class ParticipantsStringFormatter {
    // MARK: Lifecycle

    init(
        message: ZMConversationMessage,
        font: UIFont = .mediumFont,
        largeFont: UIFont = .largeSemiboldFont,
        textColor: UIColor = .from(scheme: .textForeground)
    ) {
        self.message = message
        self.font = font
        self.largeFont = largeFont
        self.textColor = textColor
    }

    // MARK: Internal

    struct NameList {
        let names: [String]
        let collapsed: Int
        let selfIncluded: Bool

        var totalUsers: Int {
            names.count + collapsed
        }
    }

    /// This is only used when a conversation (with a name) is started.
    func heading(
        senderName: String,
        senderIsSelf: Bool,
        convName: String
    ) -> NSAttributedString {
        // "You/Bob started the conversation"
        let key = senderIsSelf ? L10n.Localizable.Content.System.Conversation.WithName.titleYou(senderName) : L10n
            .Localizable.Content.System.Conversation.WithName.title(senderName)
        let text = key && font

        // "Italy Trip"
        let title = convName.attributedString && largeFont
        return [text, title].joined(separator: "\n".attributedString) && textColor && .lineSpacing(4)
    }

    /// Title when the subject (sender) is performing the action alone.
    func title(senderName: String, senderIsSelf: Bool) -> NSAttributedString? {
        switch message.actionType {
        case .added(herself: true) where senderIsSelf:
            return L10n.Localizable.Content.System.Conversation.Guest.youJoined && font && textColor

        case .added(herself: true),
             .left,
             .teamMemberLeave:
            let formatKey = message.actionType.formatKey
            return formatKey(senderIsSelf).localized(args: senderName) && font && textColor

        default:
            return nil
        }
    }

    /// Title when the subject (sender) performing the action on objects (names).
    func title(
        senderName: String,
        senderIsSelf: Bool,
        names: NameList,
        isSelfIncludedInUsers: Bool = false
    ) -> NSAttributedString? {
        guard !names.names.isEmpty else {
            return nil
        }

        var result: NSAttributedString
        let formatKey = message.actionType.formatKey
        let nameSequence = format(names)

        switch message.actionType {
        case .removed(reason: .legalHoldPolicyConflict):
            typealias Conversation = L10n.Localizable.Content.System.Conversation

            var senderPath = names.names.count > 1 ? "others" : "other"
            if isSelfIncludedInUsers {
                senderPath = "you"
            }
            let formatString = "content.system.conversation.\(senderPath).removed.legalhold"
            result = formatString.localized(args: nameSequence.string) && font && textColor

            let learnMore = NSAttributedString(
                string: L10n.Localizable.Content.System.MessageLegalHold.learnMore
                    .uppercased(),
                attributes: [
                    .font: font,
                    .link: WireURLs.shared.legalHoldInfo
                        .absoluteString as AnyObject,
                    .foregroundColor: SemanticColors.Label.textDefault,
                ]
            )
            return result += " " + learnMore

        case .removed(reason: .federationTermination):
            let formatString = "content.system.federation_termination.participants_removed"
                .localized(args: names.totalUsers, nameSequence.string)
            result = .markdown(from: formatString, style: .systemMessage)

            return result

        case .added(herself: false),
             .removed,
             .started(withName: .none):
            result = formatKey(senderIsSelf).localized(args: senderName, nameSequence.string) && font && textColor

        case .started(withName: .some):
            result = "\(L10n.Localizable.Content.System.Conversation.WithName.participants) \(nameSequence.string)" &&
                font && textColor

        default: return nil
        }

        return nameSequence.applyComponentAttributes(to: result)
    }

    // MARK: Private

    private let message: ZMConversationMessage
    private let font, largeFont: UIFont
    private let textColor: UIColor

    private var normalAttributes: Attributes {
        [.font: font, .foregroundColor: textColor]
    }

    private var boldAttributes: Attributes {
        [.font: font, .foregroundColor: textColor]
    }

    private var linkAttributes: Attributes {
        [.link: ParticipantsCellViewModel.showMoreLinkURL]
    }

    /// Returns a `FormatSequence` describing a list of names. The list is comprised
    /// of usernames for shown users (complete with punctuation) and a count string
    /// for collapsed users, if any. E.g: "x, y, z, and 3 others"
    private func format(_ nameList: NameList) -> FormatSequence {
        guard !nameList.names.isEmpty else {
            preconditionFailure()
        }
        let result = FormatSequence()

        // all team users added?
        if let linkText = linkTextForWholeTeam(nameList) {
            result.append(linkText, with: linkAttributes)
            return result
        }

        let names = nameList.names
        let attrsForLastName = nameList.selfIncluded ? normalAttributes : boldAttributes

        switch names.count {
        case 1:
            // "x"
            result.append(names.last!, with: attrsForLastName)

        case 2:
            // "x and y"
            let part = L10n.Localizable.Content.System.participants1Other(names.first!, names.last!)
            result.append(part, with: normalAttributes)
            result.define(boldAttributes, forComponent: names.first!)
            result.define(attrsForLastName, forComponent: names.last!)

        default:
            // "x, y, "
            result.append(names.dropLast().map { $0 + ", " }.joined(), with: boldAttributes)

            if nameList.collapsed > 0 {
                // "you/z, "
                result.append(names.last! + ", ", with: attrsForLastName)
                // "and X others
                let linkText = L10n.Localizable.Content.System.StartedConversation.TruncatedPeople
                    .others(nameList.collapsed)
                let linkPart = L10n.Localizable.Content.System.StartedConversation.truncatedPeople(linkText)
                result.append(linkPart, with: normalAttributes)
                result.define(linkAttributes, forComponent: linkText)
            } else {
                // "and you/z"
                let lastPart = L10n.Localizable.Content.System.StartedConversation.truncatedPeople(names.last!)
                result.append(lastPart, with: normalAttributes)
                result.define(attrsForLastName, forComponent: names.last!)
            }
        }

        return result
    }

    private func linkTextForWholeTeam(_ nameList: NameList) -> String? {
        guard
            let systemMessage = message as? ZMSystemMessage,
            systemMessage.allTeamUsersAdded,
            (message.conversationLike as? CanManageAccessProvider)?.canManageAccess ?? false
        else {
            return nil
        }

        // we only collapse whole team if there are more than 10 participants
        guard nameList.totalUsers + Int(systemMessage.numberOfGuestsAdded) > 10 else {
            return nil
        }

        if systemMessage.numberOfGuestsAdded > 0 {
            return L10n.Localizable.Content.System.StartedConversation.CompleteTeam
                .guests(String(systemMessage.numberOfGuestsAdded))
        } else {
            return L10n.Localizable.Content.System.StartedConversation.completeTeam
        }
    }
}
