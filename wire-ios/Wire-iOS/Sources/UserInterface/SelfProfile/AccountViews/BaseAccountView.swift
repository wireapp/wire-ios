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
    let selectionView = ShapeView()
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
            return false
        case .current:
            return account.unreadConversationCount > 0
        case .others:
            return ((SessionManager.shared?.accountManager.totalUnreadCount ?? 0) - account.unreadConversationCount) > 0
        }
    }

    func updateAppearance() {
        selectionView.isHidden = !selected
        selectionView.hostedLayer.strokeColor = UIColor.accent().cgColor
        layoutSubviews()
    }

    var onTap: (Account) -> Void = { _ in }

    var accessibilityState: String {
        typealias ConversationListHeaderAccessibilityLocale = L10n.Localizable.ConversationList.Header.SelfTeam.AccessibilityValue
        var result = selected ? ConversationListHeaderAccessibilityLocale.active : ConversationListHeaderAccessibilityLocale.inactive

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
            selfUserObserver = UserChangeInfo.add(observer: self, for: userSession.providedSelfUser, in: userSession)
        }

        selectionView.hostedLayer.strokeColor = UIColor.accent().cgColor
        selectionView.hostedLayer.fillColor = UIColor.clear.cgColor
        selectionView.hostedLayer.lineWidth = 1.5

        [imageViewContainer, outlineView, selectionView].forEach(addSubview)

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

        self.unreadCountToken = NotificationCenter.default.addObserver(forName: .AccountUnreadCountDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateAppearance()
        }

        updateAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        selectionView.hostedLayer.strokeColor = UIColor.accent().cgColor
    }

    // MARK: - Setup constraints

    func setupConstraints(iconWidth: CGFloat) {
        let containerInset: CGFloat = 6

        [self, selectionView, imageViewContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate(
            selectionView.fitInConstraints(view: imageViewContainer, inset: -1) +
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
            ])
    }

    // MARK: - Actions

    func update() {
        if self.autoUpdateSelection {
            self.selected = SessionManager.shared?.accountManager.selectedAccount == self.account
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
        return TeamImageView.Content(imageData: imageData, name: name)
    }

}

// MARK: - Account Extension

extension Account {

    var teamImageViewContent: TeamImageView.Content? {
        return TeamImageView.Content(imageData: teamImageData, name: teamName)
    }
}
