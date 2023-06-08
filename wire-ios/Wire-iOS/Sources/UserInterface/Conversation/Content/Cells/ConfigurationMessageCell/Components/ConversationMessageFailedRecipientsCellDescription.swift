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
    weak var sectionDelegate: ConversationMessageSectionControllerDelegate?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 5

    var isFullWidth: Bool = true
    var supportsActions: Bool = false
    var containsHighlightableContent: Bool = false

    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    init(failedUsers: [UserType], isCollapsed: Bool, buttonAction: @escaping Completion) {
        configuration = View.Configuration(title: ConversationMessageFailedRecipientsCellDescription.configureTitle(for: failedUsers),
                                           content: ConversationMessageFailedRecipientsCellDescription.configureContent(for: failedUsers),
                                           isCollapsed: isCollapsed,
                                           hasMultipleUsers: (failedUsers.count > 1),
                                           infoImage: nil,
                                           buttonAction: buttonAction)
    }

    private static func configureTitle(for failedUsers: [UserType]) -> String {
        guard failedUsers.count > 1 else {
            return ""
        }

        return SystemContent.FailedtosendParticipants.count(failedUsers.count)
    }

    private static func configureContent(for failedUsers: [UserType]) -> String {
        let userNames = failedUsers.compactMap { $0.name }.joined(separator: ", ")
        let content = SystemContent.FailedtosendParticipants.willGetLater(userNames)

        return SystemContent.FailedParticipants.learnMore(content, URL.wr_backendOfflineLearnMore.absoluteString)
    }

}
