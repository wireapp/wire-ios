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

// MARK: - TopPeopleLineCollectionViewController

final class TopPeopleLineCollectionViewController: NSObject {
    var topPeople = [ZMConversation]()

    weak var delegate: TopPeopleLineCollectionViewControllerDelegate?

    private func conversation(at indexPath: IndexPath) -> ZMConversation {
        topPeople[indexPath.item % topPeople.count]
    }
}

// MARK: UICollectionViewDataSource

extension TopPeopleLineCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        topPeople.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: TopPeopleCell.self, for: indexPath)
        cell.conversation = conversation(at: indexPath)
        return cell
    }
}

// MARK: UICollectionViewDelegate

extension TopPeopleLineCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let conversation = conversation(at: indexPath)
        delegate?.topPeopleLineCollectionViewControllerDidSelect(conversation)
    }
}

// MARK: UICollectionViewDelegateFlowLayout

extension TopPeopleLineCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        .init(top: 6, left: 0, bottom: 0, right: 0)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        .init(width: 56, height: 78)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        12
    }
}
