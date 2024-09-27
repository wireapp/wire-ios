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

final class ConversationFailedToAddParticipantsSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(failedUsers: [UserType], isCollapsed: Bool, buttonAction: @escaping Completion) {
        self.configuration = View.Configuration(
            title: ConversationFailedToAddParticipantsSystemMessageCellDescription.configureTitle(for: failedUsers),
            content: ConversationFailedToAddParticipantsSystemMessageCellDescription.configureContent(for: failedUsers),
            isCollapsed: isCollapsed,
            icon: .init(resource: .attention),
            buttonAction: buttonAction
        )
    }

    // MARK: Internal

    typealias SystemContent = L10n.Localizable.Content.System
    typealias View = FailedUsersSystemMessageCell

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 26.0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    // MARK: Private

    private static func configureTitle(for failedUsers: [UserType]) -> NSAttributedString? {
        guard failedUsers.count > 1 else {
            return nil
        }

        let title = SystemContent.FailedtoaddParticipants.count(failedUsers.count)
        return .markdown(from: title, style: .errorLabelStyle)
    }

    private static func configureContent(for failedUsers: [UserType]) -> NSAttributedString {
        let keyString = "content.system.failedtoadd_participants.could_not_be_added"

        let userNames = failedUsers.compactMap(\.name)
        let userNamesJoined = userNames.joined(separator: ", ")
        let text = keyString.localized(args: userNames.count, userNamesJoined)

        let attributedText = NSAttributedString.errorSystemMessage(withText: text, andHighlighted: userNamesJoined)
        let learnMore = NSAttributedString.unreachableBackendLearnMoreLink

        return [attributedText, learnMore].joined(separator: " ".attributedString)
    }
}
