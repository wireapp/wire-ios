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
import WireDataModel

// MARK: - InviteTeamMemberSectionDelegate

protocol InviteTeamMemberSectionDelegate: AnyObject {
    func inviteSectionDidRequestTeamManagement()
}

// MARK: - InviteTeamMemberSection

final class InviteTeamMemberSection: NSObject, CollectionViewSectionController {
    var team: Team?
    weak var delegate: InviteTeamMemberSectionDelegate?

    init(team: Team?) {
        super.init()
        self.team = team
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(
            InviteTeamMemberCell.self,
            forCellWithReuseIdentifier: InviteTeamMemberCell.zm_reuseIdentifier
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    var isHidden: Bool {
        if let count = team?.members.count {
            return count > 1
        }

        return false
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: InviteTeamMemberCell.zm_reuseIdentifier, for: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.inviteSectionDidRequestTeamManagement()
    }
}
