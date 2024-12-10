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

        let cancelButton = UIBarButtonItem.createNavigationLeftBarButtonItem(
            title: L10n.Localizable.General.cancel,
            action: UIAction { [weak self] _ in
                _ = self?.searchController.searchBar.resignFirstResponder()
                self?.navigationController?.dismiss(animated: true)
            }
        )
        cancelButton.accessibilityLabel = L10n.Accessibility.ContactsList.CancelButton.description
        cancelButton.accessibilityIdentifier = "cancel"
        navigationItem.leftBarButtonItem = cancelButton

        let createGroupButton = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: L10n.Localizable.Peoplepicker.Button.createConversation,
            action: UIAction { [weak self] _ in
                guard let self else { return }
                let conversationCreationController = createGroupConversationUIBuilder.build()
                navigationController?.pushViewController(conversationCreationController, animated: true)
            }
        )

        // We explicitly set the font here because the font provided inside createNavigationRightBarButtonItem
        // might not reflect the required design specifications in this particular context.
        // This ensures that the button uses a custom font as needed for consistency across the app.
        // The only change between the two is the weight. In this case it's semibold.
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        createGroupButton.setTitleTextAttributes([.font: font], for: .normal)
        createGroupButton.accessibilityLabel = L10n.Localizable.Peoplepicker.Button.createConversation
        createGroupButton.accessibilityIdentifier = "create_group"
        navigationItem.rightBarButtonItem = createGroupButton
    }
}
