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
import WireSyncEngine

/// The subclasses of BaseAccountView must conform to AccountViewType,
/// otherwise `init?(account: Account, user: ZMUser? = nil)` returns nil
class BaseAccountView: UIView {

    // MARK: - Properties

    var autoUpdateSelection = true

    let imageViewContainer = UIView()
    private let outlineView = UIView()
    private var selfUserObserver: NSObjectProtocol!
    let account: Account
    // availability status

    var onTap: (Account) -> Void = { _ in }

    // MARK: - Init

    init(account: Account, user: ZMUser? = nil, displayContext: DisplayContext) {
        self.account = account

        super.init(frame: .zero)

        addSubview(imageViewContainer)
        addSubview(outlineView)

        let iconWidth: CGFloat
        switch displayContext {
        case .conversationListHeader:
            iconWidth = CGFloat.ConversationListHeader.avatarSize
        case .accountSelector:
            iconWidth = CGFloat.AccountView.iconWidth
        }

        setupConstraints(iconWidth: iconWidth)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Setup constraints

    func setupConstraints(iconWidth: CGFloat) {

        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false

        let containerInset: CGFloat = 6
        NSLayoutConstraint.activate(
            [
                imageViewContainer.topAnchor.constraint(equalTo: topAnchor, constant: containerInset),
                imageViewContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
                widthAnchor.constraint(greaterThanOrEqualTo: imageViewContainer.widthAnchor),

                imageViewContainer.widthAnchor.constraint(equalToConstant: iconWidth),
                imageViewContainer.heightAnchor.constraint(equalTo: imageViewContainer.widthAnchor),

                imageViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -containerInset),
                imageViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: containerInset),
                imageViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -containerInset),
                widthAnchor.constraint(lessThanOrEqualToConstant: 128)
            ]
        )
    }

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        onTap(account)
    }
}

// MARK: - Nested Types

/// For controlling size of BaseAccountView
enum DisplayContext {
    case conversationListHeader
    case accountSelector
}

// MARK: - TeamType Extension

extension TeamType {

    var teamImageViewContent: TeamImageView.Content? {
        .init(imageData: imageData, name: name)
    }

}

// MARK: - Account Extension

extension Account {

    var teamImageViewContent: TeamImageView.Content? {
        .init(imageData: teamImageData, name: teamName)
    }
}
