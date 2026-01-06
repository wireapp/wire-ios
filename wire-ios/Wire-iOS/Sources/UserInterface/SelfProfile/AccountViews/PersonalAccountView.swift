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
import WireDataModel
import WireDesign
import WireSyncEngine

final class PersonalAccountView: BaseAccountView {

    // MARK: - Properties

    private let userImageView = {
        let avatarImageView = AvatarImageView(frame: .zero)
        avatarImageView.container.backgroundColor = SemanticColors.View.backgroundDefaultWhite

        avatarImageView.initialsFont = .smallSemiboldFont
        avatarImageView.initialsColor = SemanticColors.Label.textDefault

        return avatarImageView
    }()

    private var conversationListObserver: NSObjectProtocol!
    private var connectionRequestObserver: NSObjectProtocol!

    // MARK: - Init

    override init(account: Account, user: ZMUser? = nil, displayContext: DisplayContext) {
        super.init(account: account, user: user, displayContext: displayContext)

        self.isAccessibilityElement = true
        self.accessibilityTraits = .button
        self.shouldGroupAccessibilityChildren = true
        self.accessibilityIdentifier = "personal team"

        selectionView.layer.masksToBounds = true

        if let userSession = ZMUserSession.shared() {
            self.conversationListObserver = ConversationListChangeInfo.add(
                observer: self,
                for: ConversationList.conversations(inUserSession: userSession),
                userSession: userSession
            )
            self.connectionRequestObserver = ConversationListChangeInfo.add(
                observer: self,
                for: ConversationList.pendingConnectionConversations(inUserSession: userSession),
                userSession: userSession
            )
        }

        imageViewContainer.addSubview(userImageView)
        userImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            userImageView.topAnchor.constraint(equalTo: imageViewContainer.topAnchor, constant: 2),
            userImageView.bottomAnchor.constraint(equalTo: imageViewContainer.bottomAnchor, constant: -2),
            userImageView.leadingAnchor.constraint(equalTo: imageViewContainer.leadingAnchor, constant: 2),
            userImageView.trailingAnchor.constraint(equalTo: imageViewContainer.trailingAnchor, constant: -2)
        ])

        update()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionView.layer.cornerRadius = selectionView.bounds.width / 2
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func update() {
        super.update()

        accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam
            .accessibilityValue(account.userName) + " " + accessibilityState
        if let imageData = account.imageData, let avatarImage = UIImage(data: imageData) {
            userImageView.avatar = .image(avatarImage)
        } else {
            let personName = PersonName.person(withName: account.userName, schemeTagger: nil)
            userImageView.avatar = .text(personName.initials)
        }
    }
}

// MARK: - User Observing

extension PersonalAccountView {

    override func userDidChange(_ changeInfo: UserChangeInfo) {
        super.userDidChange(changeInfo)
        if changeInfo.nameChanged || changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged {
            update()
        }
    }
}
