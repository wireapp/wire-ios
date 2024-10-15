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

extension StartUIViewController {

    func setupNavigationBarButtonItems() {
        let cancelButton = UIBarButtonItem(
            title: L10n.Localizable.General.cancel,
            style: .plain,
            target: self,
            action: #selector(onDismiss)
        )

        cancelButton.accessibilityLabel = L10n.Accessibility.ContactsList.CancelButton.description
        cancelButton.accessibilityIdentifier = "cancel"

        navigationItem.rightBarButtonItem = cancelButton

        let button = UIButton(type: .system)
        button.setTitle(L10n.Localizable.Peoplepicker.Button.createConversation, for: .normal)
        button.titleLabel?.font = UIFont.font(for: .h3)

        let action = UIAction { [weak self] _ in
            guard let self else { return }
            let conversationCreationController = ConversationCreationController(
                preSelectedParticipants: nil,
                userSession: userSession
            )
            navigationController?.pushViewController(conversationCreationController, animated: false)
        }
        button.addAction(action, for: .touchUpInside)

        button.accessibilityLabel = L10n.Localizable.Peoplepicker.Button.createConversation
        button.accessibilityIdentifier = "create_group"

        let createGroupButton = UIBarButtonItem(customView: button)

        navigationItem.leftBarButtonItem = createGroupButton
    }

    @objc
    func onDismiss() {
        _ = searchController.searchBar.resignFirstResponder()
        navigationController?.dismiss(animated: true)
    }
}
