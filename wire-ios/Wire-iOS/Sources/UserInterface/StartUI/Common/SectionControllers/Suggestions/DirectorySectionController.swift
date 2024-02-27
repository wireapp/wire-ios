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
import UIKit
import WireSyncEngine

final class DirectorySectionController: SearchSectionController {

    var suggestions: [ZMSearchUser] = []
    weak var delegate: SearchSectionControllerDelegate?
    var token: AnyObject?
    weak var collectionView: UICollectionView?

    override var isHidden: Bool {
        return self.suggestions.isEmpty
    }

    override var sectionTitle: String {
        return L10n.Localizable.Peoplepicker.Header.directory
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
        guard let userSession = ZMUserSession.shared() else { return }
        self.token = UserChangeInfo.add(searchUserObserver: self, in: userSession)

        self.collectionView = collectionView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return suggestions.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let user = suggestions[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserCell.zm_reuseIdentifier, for: indexPath) as! UserCell
        if let selfUser = ZMUser.selfUser() {
            cell.configure(
                user: user,
                isSelfUserPartOfATeam: selfUser.hasTeam
            )
        } else {
            assertionFailure("ZMUser.selfUser() is nil")
        }
        cell.showSeparator = (suggestions.count - 1) != indexPath.row
        cell.userTypeIconView.isHidden = true
        cell.accessoryIconView.isHidden = true
        cell.connectButton.isHidden = !user.canBeUnblocked
        if user.canBeUnblocked {
            cell.accessibilityHint = L10n.Accessibility.ContactsList.PendingConnection.hint
        }
        cell.connectButton.tag = indexPath.row
        cell.connectButton.addTarget(self, action: #selector(connect(_:)), for: .touchUpInside)

        return cell
    }

    @objc func connect(_ sender: AnyObject) {
        guard let button = sender as? UIButton else { return }

        let indexPath = IndexPath(row: button.tag, section: 0)
        let user = suggestions[indexPath.row]

        if user.isBlocked {
            user.accept { [weak self] error in
                guard
                    let strongSelf = self,
                    let error = error as? LocalizedError
                else {
                    return
                }

                self?.delegate?.searchSectionController(strongSelf, wantsToDisplayError: error)
            }
        } else {
            user.connect { [weak self] error in
                guard
                    let strongSelf = self,
                    let error = error as? ConnectToUserError
                else {
                    return
                }

                self?.delegate?.searchSectionController(strongSelf, wantsToDisplayError: error)
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = suggestions[indexPath.row]
        delegate?.searchSectionController(self, didSelectUser: user, at: indexPath)
    }

}

extension DirectorySectionController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged else { return }

        collectionView?.reloadData()
    }

}
