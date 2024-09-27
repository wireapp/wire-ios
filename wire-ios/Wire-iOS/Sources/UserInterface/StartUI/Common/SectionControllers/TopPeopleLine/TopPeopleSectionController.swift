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
import WireSyncEngine

// MARK: - TopPeopleSectionController

final class TopPeopleSectionController: SearchSectionController {
    // MARK: Lifecycle

    init(topConversationsDirectory: TopConversationsDirectory!) {
        self.topConversationsDirectory = topConversationsDirectory

        super.init()

        createInnerCollectionView()

        if let topConversationsDirectory {
            self.token = topConversationsDirectory.add(observer: self)
            innerCollectionViewController.topPeople = topConversationsDirectory.topConversations
            topConversationsDirectory.refreshTopConversations()
        }
        innerCollectionViewController.delegate = self
        innerCollectionView.reloadData()
    }

    // MARK: Internal

    var token: Any?
    weak var delegate: SearchSectionControllerDelegate?

    override var isHidden: Bool {
        if let topConversationsDirectory {
            topConversationsDirectory.topConversations.isEmpty
        } else {
            true
        }
    }

    override var sectionTitle: String {
        L10n.Localizable.Peoplepicker.Header.topPeople
    }

    func createInnerCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        innerCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        innerCollectionView.translatesAutoresizingMaskIntoConstraints = false
        innerCollectionView.backgroundColor = .clear
        innerCollectionView.bounces = true
        innerCollectionView.allowsMultipleSelection = false
        innerCollectionView.showsHorizontalScrollIndicator = false
        innerCollectionView.isDirectionalLockEnabled = true
        innerCollectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
        innerCollectionView.register(TopPeopleCell.self, forCellWithReuseIdentifier: TopPeopleCell.zm_reuseIdentifier)

        innerCollectionView.delegate = innerCollectionViewController
        innerCollectionView.dataSource = innerCollectionViewController
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)

        collectionView?.register(
            CollectionViewContainerCell.self,
            forCellWithReuseIdentifier: CollectionViewContainerCell.zm_reuseIdentifier
        )
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 97)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CollectionViewContainerCell.zm_reuseIdentifier,
            for: indexPath
        ) as! CollectionViewContainerCell
        cell.collectionView = innerCollectionView
        return cell
    }

    // MARK: Private

    private var innerCollectionView: UICollectionView!
    private let innerCollectionViewController = TopPeopleLineCollectionViewController()
    private let topConversationsDirectory: TopConversationsDirectory!
}

// MARK: TopConversationsDirectoryObserver

extension TopPeopleSectionController: TopConversationsDirectoryObserver {
    func topConversationsDidChange() {
        innerCollectionViewController.topPeople = topConversationsDirectory.topConversations
        innerCollectionView.reloadData()
    }
}

// MARK: TopPeopleLineCollectionViewControllerDelegate

extension TopPeopleSectionController: TopPeopleLineCollectionViewControllerDelegate {
    func topPeopleLineCollectionViewControllerDidSelect(_ conversation: ZMConversation) {
        delegate?.searchSectionController(self, didSelectConversation: conversation, at: IndexPath(row: 0, section: 0))
    }
}
