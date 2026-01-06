//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    let selectionView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.accent().cgColor
        return view
    }()

    private var unreadCountToken: Any?
    private var selfUserObserver: NSObjectProtocol!
    let account: Account

    var unreadCountStyle: AccountUnreadCountStyle = .none {
        didSet { updateAppearance() }
    }

    var selected: Bool = true {
        didSet { updateAppearance() }
    }

    var hasUnreadMessages: Bool {
        switch unreadCountStyle {
        case .none:
            false
        case .current:
            account.unreadConversationCount > 0
        case .others:
            ((SessionManager.shared?.accountManager.totalUnreadCount ?? 0) - account.unreadConversationCount) > 0
        }
    }

    func updateAppearance() {
        selectionView.isHidden = !selected
        selectionView.layer.borderColor = UIColor.accent().cgColor
        layoutSubviews()
    }

    var onTap: (Account) -> Void = { _ in }

    var accessibilityState: String {
        typealias ConversationListHeaderAccessibilityLocale = L10n.Localizable.ConversationList.Header.SelfTeam
            .AccessibilityValue
        var result = selected ? ConversationListHeaderAccessibilityLocale
            .active : ConversationListHeaderAccessibilityLocale.inactive

        if hasUnreadMessages {
            result += "\(L10n.Localizable.ConversationList.Header.SelfTeam.AccessibilityValue.hasNewMessages)"
        }

        return result
    }

    // MARK: - Init

    init(account: Account, user: ZMUser? = nil, displayContext: DisplayContext) {
        self.account = account

        super.init(frame: .zero)

        if let userSession = SessionManager.shared?.activeUserSession {
            self.selfUserObserver = UserChangeInfo.add(
                observer: self,
                for: userSession.providedSelfUser,
                in: userSession
            )
        }

        selectionView.layer.borderColor = UIColor.accent().cgColor

        [imageViewContainer, outlineView, selectionView].forEach(addSubview)

        let iconWidth = switch displayContext {
        case .conversationListHeader:
            CGFloat.ConversationListHeader.avatarSize
        case .accountSelector:
            CGFloat.AccountView.iconWidth
        }

        setupConstraints(iconWidth: iconWidth)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tapGesture)

        self.unreadCountToken = NotificationCenter.default.addObserver(
            forName: .AccountUnreadCountDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAppearance()
        }

        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func layoutSubviews() {
        super.layoutSubviews()
        // Make selection view match container's corner radius if needed
        selectionView.layer.cornerRadius = imageViewContainer.layer.cornerRadius
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        selectionView.layer.borderColor = UIColor.accent().cgColor
    }

    // MARK: - Setup constraints

    func setupConstraints(iconWidth: CGFloat) {
        let containerInset: CGFloat = 6

        [self, selectionView, imageViewContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            selectionView.leadingAnchor.constraint(equalTo: imageViewContainer.leadingAnchor, constant: -1),
            selectionView.trailingAnchor.constraint(equalTo: imageViewContainer.trailingAnchor, constant: 1),
            selectionView.topAnchor.constraint(equalTo: imageViewContainer.topAnchor, constant: -1),
            selectionView.bottomAnchor.constraint(equalTo: imageViewContainer.bottomAnchor, constant: 1),

            imageViewContainer.topAnchor.constraint(equalTo: topAnchor, constant: containerInset),
            imageViewContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            widthAnchor.constraint(greaterThanOrEqualTo: imageViewContainer.widthAnchor),

            imageViewContainer.widthAnchor.constraint(equalToConstant: iconWidth),
            imageViewContainer.heightAnchor.constraint(equalTo: imageViewContainer.widthAnchor),

            imageViewContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -containerInset),
            imageViewContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: containerInset),
            imageViewContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -containerInset),
            widthAnchor.constraint(lessThanOrEqualToConstant: 128)
        ])
    }

    // MARK: - Actions

    func update() {
        if autoUpdateSelection {
            selected = SessionManager.shared?.accountManager.selectedAccount == account
        }
    }

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        onTap(account)
    }
}

// MARK: - Nested Types

enum AccountUnreadCountStyle {
    /// Do not display an unread count.
    case none
    /// Display unread count only considering current account.
    case current
    /// Display unread count only considering other accounts.
    case others
}

/// For controlling size of BaseAccountView
enum DisplayContext {
    case conversationListHeader
    case accountSelector
}

// MARK: - ZMConversationListObserver Conformance

extension BaseAccountView: ZMConversationListObserver {

    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
        updateAppearance()
    }

    func conversationInsideList(_ list: ConversationList, didChange changeInfo: ConversationChangeInfo) {
        updateAppearance()
    }
}

// MARK: - UserObserving Conformance

extension BaseAccountView: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.accentColorValueChanged {
            updateAppearance()
        }
    }
}

// MARK: - TeamType Extension

extension TeamType {

    var teamImageViewContent: TeamImageView.Content? {
        TeamImageView.Content(imageData: imageData, name: name)
    }

}

// MARK: - Account Extension

extension Account {

    var teamImageViewContent: TeamImageView.Content? {
        TeamImageView.Content(imageData: teamImageData, name: teamName)
    }
}
