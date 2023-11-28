//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

enum OutgoingConnectionBottomBarAction: UInt {
    case cancel, archive
}

final class OutgoingConnectionViewController: UIViewController {

    typealias Connection = L10n.Accessibility.Connection

    private let cancelButton = IconButton()
    private let archiveButton = IconButton()

    var buttonCallback: ((OutgoingConnectionBottomBarAction) -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.view.backgroundColor = SemanticColors.View.backgroundConversationView
        setupCancelButton()
        setupArchiveButton()
        [cancelButton, archiveButton].forEach(view.addSubview)
    }

    private func setupCancelButton() {
        cancelButton.accessibilityLabel = Connection.CancelButton.description
        cancelButton.setIcon(.undo, size: .tiny, for: .normal)
        cancelButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        cancelButton.setIconColor(SemanticColors.Icon.foregroundDefault.withAlphaComponent(0.4), for: .highlighted)
        cancelButton.setTitle("profile.cancel_connection_button_title".localized, for: .normal)
        cancelButton.titleLabel?.font = FontSpec.normalSemiboldFont.font!
        cancelButton.setTitleColor(SemanticColors.Label.textDefault, for: .normal)
        cancelButton.setTitleImageSpacing(24)
        cancelButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func setupArchiveButton() {
        archiveButton.accessibilityLabel = Connection.ArchiveButton.description
        archiveButton.setIcon(.archive, size: .tiny, for: .normal)
        archiveButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        archiveButton.setIconColor(SemanticColors.Icon.foregroundDefault.withAlphaComponent(0.4), for: .highlighted)
        archiveButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    private func createConstraints() {
        [cancelButton, archiveButton].prepareForLayout()
        NSLayoutConstraint.activate([
          cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
          cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
          cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24),
          archiveButton.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),
          archiveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    @objc private func buttonTapped(sender: IconButton) {
        switch sender {
        case cancelButton: buttonCallback?(.cancel)
        case archiveButton: buttonCallback?(.archive)
        default: break
        }
    }

}
