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

final class TeamAccountView: BaseAccountView {

    private let imageView: TeamImageView
    private var teamObserver: NSObjectProtocol!
    private var conversationListObserver: NSObjectProtocol!

    required init?(user: ZMUser?, account: Account, displayContext: DisplayContext) {
        if let content = user?.team?.teamImageViewContent ?? account.teamImageViewContent {
            self.imageView = TeamImageView(content: content, style: .big)
        } else {
            return nil
        }

        super.init(account: account, user: user, displayContext: displayContext)

        isAccessibilityElement = true
        accessibilityTraits = .button
        shouldGroupAccessibilityChildren = true

        imageView.contentMode = .scaleAspectFill
        imageViewContainer.addSubview(imageView)

        selectionView.layer.masksToBounds = true

        createConstraints()
        update()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tapGesture)

        if let team = user?.team {
            self.teamObserver = TeamChangeInfo.add(observer: self, for: team)
            team.requestImage()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        selectionView.layer.cornerRadius = 6
    }

    private func createConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewContainer.translatesAutoresizingMaskIntoConstraints = false

        let insets = Constants.teamAccountViewImageInsets
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: imageViewContainer.leadingAnchor, constant: insets.left),
            imageView.topAnchor.constraint(equalTo: imageViewContainer.topAnchor, constant: insets.top),
            imageViewContainer.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: insets.right),
            imageViewContainer.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: insets.bottom)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update() {
        super.update()
        accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam
            .accessibilityValue(account.teamName ?? "") + " " + accessibilityState
        accessibilityIdentifier = "\(account.teamName ?? "") team"
    }
}

extension TeamAccountView: TeamObserver {

    func teamDidChange(_ changeInfo: TeamChangeInfo) {

        if changeInfo.imageDataChanged {
            changeInfo.team.requestImage()
        }

        if let content = changeInfo.team.teamImageViewContent {
            imageView.content = content
        }
    }
}
