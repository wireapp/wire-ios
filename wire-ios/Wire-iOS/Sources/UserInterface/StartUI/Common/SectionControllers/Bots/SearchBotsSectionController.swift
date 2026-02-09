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

final class SearchBotsSectionController: SearchSectionController {

    weak var delegate: SearchBotsSectionDelegate?

    var bots: [any Bot] = []

    let canSelfUserManageTeam: Bool

    init(canSelfUserManageTeam: Bool) {
        self.canSelfUserManageTeam = canSelfUserManageTeam
        super.init()
    }

    override var isHidden: Bool {
        bots.isEmpty
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(
            OpenBotAdminCell.self,
            forCellWithReuseIdentifier: OpenBotAdminCell.zm_reuseIdentifier
        )
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if canSelfUserManageTeam {
            bots.count + 1
        } else {
            bots.count
        }
    }

    override var sectionTitle: String {
        L10n.Localizable.Peoplepicker.Header.apps
    }

    func bot(for indexPath: IndexPath) -> any Bot {
        if canSelfUserManageTeam {
            bots[indexPath.row - 1]
        } else {
            bots[indexPath.row]
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize.zero
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if canSelfUserManageTeam, indexPath.row == 0 {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: OpenBotAdminCell.zm_reuseIdentifier,
                for: indexPath
            )
        } else {
            let bot = bot(for: indexPath)

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserCell.zm_reuseIdentifier,
                for: indexPath
            ) as! UserCell
            if let selfUser = ZMUser.selfUser() {
                cell.configure(
                    user: bot,
                    isSelfUserPartOfATeam: selfUser.hasTeam
                )
            } else {
                assertionFailure("ZMUser.selfUser() is nil")
            }
            cell.accessoryIconView.isHidden = false
            cell.showSeparator = (bots.count - 1) != indexPath.row

            return cell
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if canSelfUserManageTeam, indexPath.row == 0 {
            delegate?.addBotsSectionDidRequestOpenBotsAdmin()
        } else {
            let bot = bot(for: indexPath)
            delegate?.searchSectionController(self, didSelectUser: bot, at: indexPath)
        }
    }

}
