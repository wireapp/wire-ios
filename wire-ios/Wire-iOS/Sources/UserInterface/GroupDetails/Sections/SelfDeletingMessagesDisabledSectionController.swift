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

import Foundation
import WireSyncEngine

final class SelfDeletingMessagesDisabledSectionController: GroupDetailsSectionController {

    let cellReuseIdentifier: String = GroupDetailsTimeoutOptionsCell.zm_reuseIdentifier

    // MARK: - Properties

    private let conversation: GroupDetailsConversationType
    private var footerView = SectionFooter(frame: .zero)

    override var isHidden: Bool {
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return true
        }
        return !user.canModifyEphemeralSettings(in: conversation)
    }

    init(
        conversation: GroupDetailsConversationType,
        collectionView: UICollectionView
    ) {
        self.conversation = conversation

        SectionFooter.register(collectionView: collectionView)
    }

    // MARK: - Collection View

    override var sectionTitle: String {
        ""
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView.flatMap(GroupDetailsTimeoutOptionsCell.register)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellReuseIdentifier,
            for: indexPath
        ) as! GroupDetailsTimeoutOptionsCell

        cell.configure(with: conversation)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        false
    }

    // MARK: - Header

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        .zero
    }

    // MARK: - Footer

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {

        footerView.titleLabel.text = L10n.Localizable.GroupDetails.ReceiptOptionsCell.description
        footerView.size(fittingWidth: collectionView.bounds.width)
        return footerView.bounds.size
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else { return super.collectionView(
            collectionView,
            viewForSupplementaryElementOfKind: kind,
            at: indexPath
        ) }

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: SectionFooter.reuseIdentifier,
            for: indexPath
        ) as! SectionFooter

        view.titleLabel.text = L10n.Localizable.GroupDetails.TimeoutOptionsDisabled.footer
        return view
    }

}
