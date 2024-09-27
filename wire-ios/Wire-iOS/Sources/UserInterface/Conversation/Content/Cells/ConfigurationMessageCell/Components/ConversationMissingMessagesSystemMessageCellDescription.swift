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

final class ConversationMissingMessagesSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let title = ConversationMissingMessagesSystemMessageCellDescription
            .makeAttributedString(systemMessageData: data)
        self.configuration = View.Configuration(
            icon: StyleKitIcon.exclamationMark.makeImage(
                size: .tiny,
                color: IconColors
                    .foregroundExclamationMarkInSystemMessage
            ),
            attributedText: title,
            showLine: true
        )
        self.accessibilityLabel = title.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationSystemMessageCell
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

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

    // MARK: Private

    private static func makeAttributedString(systemMessageData: ZMSystemMessageData) -> NSAttributedString {
        let string = localizedString(systemMessageData: systemMessageData)
        return NSAttributedString(string: string) && UIFont.mediumFont && LabelColors.textDefault
    }

    private static func localizedString(systemMessageData: ZMSystemMessageData) -> String {
        typealias Strings = L10n.Localizable.Content.System

        guard !systemMessageData.needsUpdatingUsers else {
            return Strings.missingMessages
        }

        let namesOfAddedUsers: [String] = systemMessageData.addedUserTypes.compactMap {
            guard let user = $0 as? UserType else { return nil }
            return user.name
        }.sorted(by: { $0 > $1 })

        let namesOfRemovedUsers: [String] = systemMessageData.removedUserTypes.compactMap {
            guard let user = $0 as? UserType else { return nil }
            return user.name
        }.sorted(by: { $0 > $1 })

        let listOfAddedUsers = ListFormatter.localizedString(byJoining: namesOfAddedUsers)
        let listOfRemovedUsers = ListFormatter.localizedString(byJoining: namesOfRemovedUsers)

        switch (namesOfAddedUsers.cardinality, namesOfRemovedUsers.cardinality) {
        case (.zero, .zero):
            return Strings.missingMessages

        case (.singular, .zero):
            return Strings.MissingMessages.UsersAdded.singular(listOfAddedUsers)

        case (.plural, .zero):
            return Strings.MissingMessages.UsersAdded.plural(listOfAddedUsers)

        case (.zero, .singular):
            return Strings.MissingMessages.UsersRemoved.singular(listOfRemovedUsers)

        case (.zero, .plural):
            return Strings.MissingMessages.UsersRemoved.plural(listOfRemovedUsers)

        case (.singular, .singular):
            return Strings.MissingMessages.UsersAddedAndRemoved.singular(listOfAddedUsers, listOfRemovedUsers)

        case (.plural, .singular):
            return Strings.MissingMessages.UsersAddedAndRemoved.pluralSingular(listOfAddedUsers, listOfRemovedUsers)

        case (.singular, .plural):
            return Strings.MissingMessages.UsersAddedAndRemoved.singularPlural(listOfAddedUsers, listOfRemovedUsers)

        case (.plural, .plural):
            return Strings.MissingMessages.UsersAddedAndRemoved.plural(listOfAddedUsers, listOfRemovedUsers)
        }
    }
}
