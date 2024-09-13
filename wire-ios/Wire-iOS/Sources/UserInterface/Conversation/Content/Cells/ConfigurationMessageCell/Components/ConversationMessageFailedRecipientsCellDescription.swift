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

final class ConversationMessageFailedRecipientsCellDescription: ConversationMessageCellDescription {
    typealias SystemContent = L10n.Localizable.Content.System
    typealias View = FailedUsersSystemMessageCell

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 5

    var isFullWidth = true
    var supportsActions = false
    var containsHighlightableContent = false

    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    init(failedUsers: [UserType], isCollapsed: Bool, buttonAction: @escaping Completion) {
        self.configuration = View
            .Configuration(
                title: ConversationMessageFailedRecipientsCellDescription.configureTitle(for: failedUsers),
                content: ConversationMessageFailedRecipientsCellDescription
                    .configureContent(for: failedUsers),
                isCollapsed: isCollapsed,
                icon: nil,
                buttonAction: buttonAction
            )
    }

    private static func configureTitle(for failedUsers: [UserType]) -> NSAttributedString? {
        guard failedUsers.count > 1 else {
            return nil
        }

        let title = SystemContent.FailedtosendParticipants.didNotGetMessage(failedUsers.count)
        return .markdown(from: title, style: .errorLabelStyle)
    }

    private static func configureContent(for failedUsers: [UserType]) -> NSAttributedString {
        var content: [NSAttributedString] = []
        /// The list of participants with complete metadata.
        let usersWithName = failedUsers.filter { !$0.hasEmptyName }.compactMap(\.name)
        if !usersWithName.isEmpty {
            let keyString = "content.system.failedtosend_participants.will_get_message_later"

            let userNamesJoined = usersWithName.joined(separator: ", ")
            let text = keyString.localized(args: usersWithName.count, userNamesJoined)

            let attributedText = NSAttributedString.errorSystemMessage(withText: text, andHighlighted: userNamesJoined)
            content.append(attributedText)
        }

        /// The list of participants with incomplete metadata.
        let usersWithoutName = failedUsers.filter(\.hasEmptyName)
        if !usersWithoutName.isEmpty {
            let keyString = "content.system.failedtosend_participants.will_never_get_message"

            let groupedByDomainUsers = groupByDomain(usersWithoutName)
            let domainsJoined = groupedByDomainUsers.joined(separator: ", ")
            let text = keyString.localized(args: groupedByDomainUsers.count, domainsJoined)

            let attributedText = NSAttributedString.errorSystemMessage(withText: text, andHighlighted: domainsJoined)
            content.append(attributedText)
        }
        let learnMore = NSAttributedString.unreachableBackendLearnMoreLink

        return content.joined(separator: "\n".attributedString) + " " + learnMore
    }

    private static func groupByDomain(_ users: [UserType]) -> [String] {
        let groupedUsers = Dictionary(grouping: users, by: \.domain)
        var usersPerDomain: [String] = []
        for (domain, users) in groupedUsers {
            let usersCountString = SystemContent.FailedtosendParticipants.count(users.count)
            usersPerDomain.append(SystemContent.FailedtosendParticipants.from(usersCountString, domain ?? ""))
        }
        return usersPerDomain
    }
}

extension NSAttributedString {
    static var unreachableBackendLearnMoreLink: NSAttributedString {
        typealias SystemContent = L10n.Localizable.Content.System

        return NSAttributedString(
            string: SystemContent.FailedParticipants.learnMore,
            attributes: [
                .font: UIFont.mediumSemiboldFont,
                .link: WireURLs.shared.unreachableBackendInfo,
            ]
        )
    }

    static func errorSystemMessage(withText text: String, andHighlighted highlighted: String) -> NSAttributedString {
        .markdown(from: text, style: .errorLabelStyle)
            .adding(font: .mediumSemiboldFont, to: highlighted)
    }
}
