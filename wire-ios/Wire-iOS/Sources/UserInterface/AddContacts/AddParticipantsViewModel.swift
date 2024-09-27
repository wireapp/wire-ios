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

struct AddParticipantsViewModel {
    // MARK: Lifecycle

    init(with context: AddParticipantsViewController.Context) {
        self.context = context
    }

    // MARK: Internal

    let context: AddParticipantsViewController.Context

    var botCanBeAdded: Bool {
        switch context {
        case .create: false
        case let .add(conversation): conversation.botCanBeAdded
        }
    }

    var selectedUsers: UserSet {
        switch context {
        case let .add(conversation) where conversation.conversationType == .oneOnOne:
            conversation.connectedUserType.map { [$0] } ?? []
        case let .create(values): values.participants
        default: []
        }
    }

    var filterConversation: ZMConversation? {
        switch context {
        case let .add(conversation) where conversation.conversationType == .group: conversation as? ZMConversation
        default: nil
        }
    }

    var showsConfirmButton: Bool {
        switch context {
        case .add: true
        case .create: false
        }
    }

    var confirmButtonTitle: String? {
        switch context {
        case .create: nil
        case let .add(conversation):
            if conversation.conversationType == .oneOnOne {
                L10n.Localizable.Peoplepicker.Button.createConversation.capitalized
            } else {
                L10n.Localizable.Peoplepicker.Button.addToConversation.capitalized
            }
        }
    }

    func title(with users: UserSet) -> String {
        users.isEmpty
            ? L10n.Localizable.Peoplepicker.Group.Title.singular.capitalized
            : L10n.Localizable.Peoplepicker.Group.Title.plural(users.count).capitalized
    }

    func rightNavigationItem(action: UIAction) -> UIBarButtonItem {
        switch context {
        case .add:
            let item = UIBarButtonItem.closeButton(action: action, accessibilityLabel: L10n.Localizable.General.close)
            item.tintColor = SemanticColors.Icon.foregroundDefault
            item.accessibilityIdentifier = "close"
            return item

        case let .create(values):
            let key = values.participants.isEmpty ? L10n.Localizable.Peoplepicker.Group.skip : L10n.Localizable
                .Peoplepicker.Group.done
            let newItem: UIBarButtonItem = .createNavigationRightBarButtonItem(
                title: key,
                action: action
            )
            newItem.tintColor = UIColor.accent()
            newItem.accessibilityIdentifier = values.participants
                .isEmpty ? "button.addpeople.skip" : "button.addpeople.create"
            return newItem
        }
    }
}
