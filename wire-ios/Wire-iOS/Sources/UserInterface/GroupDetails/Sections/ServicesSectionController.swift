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

final class ServicesSectionController: GroupDetailsSectionController {

    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private let apps: [UserType]
    private let conversation: GroupDetailsConversationType

    init(
        apps: [UserType],
        conversation: GroupDetailsConversationType,
        delegate: GroupDetailsSectionControllerDelegate
    ) {
        self.apps = apps
        self.conversation = conversation
        self.delegate = delegate
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.zm_reuseIdentifier)
    }

    override var sectionTitle: String {
        L10n.Localizable.Participants.Section.apps(apps.count).localizedUppercase
    }

    override var sectionAccessibilityIdentifier: String {
        "label.groupdetails.apps"
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        apps.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let user = apps[indexPath.row]
        let cell = collectionView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)
        if let selfUser = ZMUser.selfUser() {
            cell.configure(
                user: user,
                isSelfUserPartOfATeam: selfUser.hasTeam,
                conversation: conversation
            )
        } else {
            assertionFailure("ZMUser.selfUser() is nil")
        }
        cell.showSeparator = (apps.count - 1) != indexPath.row
        cell.accessoryIconView.isHidden = false
        cell.accessibilityIdentifier = "participants.section.apps.cell"
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.presentDetails(for: apps[indexPath.row])
    }
}
