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

import Foundation
import WireDataModel

// MARK: - ContactsSectionController

class ContactsSectionController: SearchSectionController {
    // MARK: Lifecycle

    deinit {
        selection?.remove(observer: self)
    }

    // MARK: Internal

    var contacts: [UserType] = []
    var allowsSelection = false
    weak var delegate: SearchSectionControllerDelegate?
    weak var collectionView: UICollectionView?

    var title = ""

    var selection: UserSelection? {
        didSet {
            selection?.add(observer: self)
        }
    }

    override var isHidden: Bool {
        contacts.isEmpty
    }

    override var sectionTitle: String {
        title
    }

    override var sectionAccessibilityIdentifier: String {
        "label.search.participants"
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)

        self.collectionView = collectionView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contacts.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let user = contacts[indexPath.row]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UserCell.zm_reuseIdentifier,
            for: indexPath
        ) as! UserCell
        if let selfUser = ZMUser.selfUser() {
            cell.configure(
                user: user,
                isSelfUserPartOfATeam: selfUser.hasTeam
            )
        } else {
            assertionFailure("ZMUser.selfUser() is nil")
        }
        cell.showSeparator = (contacts.count - 1) != indexPath.row
        cell.checkmarkIconView.isHidden = !allowsSelection
        cell.accessoryIconView.isHidden = true
        if allowsSelection {
            typealias CreateConversation = L10n.Accessibility.CreateConversation
            cell.accessibilityHint = cell.isSelected
                ? CreateConversation.SelectedUser.hint
                : CreateConversation.UnselectedUser.hint
        }

        let selected = selection?.users.contains(user) ?? false
        cell.isSelected = selected

        if selected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        !(selection?.hasReachedLimit ?? false)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = contacts[indexPath.row]
        selection?.add(user)

        delegate?.searchSectionController(self, didSelectUser: user, at: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let user = contacts[indexPath.row]
        selection?.remove(user)
    }
}

// MARK: UserSelectionObserver

extension ContactsSectionController: UserSelectionObserver {
    func userSelection(_ userSelection: UserSelection, wasReplacedBy users: [UserType]) {
        collectionView?.reloadData()
    }

    func userSelection(_ userSelection: UserSelection, didAddUser user: UserType) {
        collectionView?.reloadData()
    }

    func userSelection(_ userSelection: UserSelection, didRemoveUser user: UserType) {
        collectionView?.reloadData()
    }
}
