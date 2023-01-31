//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

// MARK: ArchivedListViewControllerDelegate

protocol ArchivedListViewControllerDelegate: AnyObject {
    func archivedListViewControllerWantsToDismiss(_ controller: ArchivedListViewController)
    func archivedListViewController(_ controller: ArchivedListViewController, didSelectConversation conversation: ZMConversation)
}

// MARK: - ArchivedListViewController

final class ArchivedListViewController: UIViewController {

    fileprivate var collectionView: UICollectionView!
    fileprivate let archivedNavigationBar = ArchivedNavigationBar(title: L10n.Localizable.ArchivedList.title.capitalized)
    fileprivate let cellReuseIdentifier = "ConversationListCellArchivedIdentifier"
    fileprivate let swipeIdentifier = "ArchivedList"
    fileprivate let viewModel = ArchivedListViewModel()
    fileprivate let layoutCell = ConversationListCell()
    fileprivate var actionController: ConversationActionController?
    fileprivate var startCallController: ConversationCallController?

    weak var delegate: ArchivedListViewControllerDelegate?

    required init() {
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        createViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityViewIsModal = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func createViews() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ConversationListCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16 + UIScreen.safeArea.bottom, right: 0)
        collectionView.accessibilityIdentifier = "archived conversation list"

        [archivedNavigationBar, collectionView].forEach(view.addSubview)
        archivedNavigationBar.dismissButtonHandler = {
            self.delegate?.archivedListViewControllerWantsToDismiss(self)
        }
        view.backgroundColor = SemanticColors.View.backgroundConversationList
    }

    private func createConstraints() {
        [archivedNavigationBar, collectionView].prepareForLayout()
        NSLayoutConstraint.activate([
            archivedNavigationBar.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.safeArea.top),
            archivedNavigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            archivedNavigationBar.rightAnchor.constraint(equalTo: view.rightAnchor),
            archivedNavigationBar.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
          collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
          collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
          collectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    // MARK: - Accessibility

    override func accessibilityPerformEscape() -> Bool {
        self.delegate?.archivedListViewControllerWantsToDismiss(self)
        return true
    }

}

// MARK: - CollectionViewDelegate

extension ArchivedListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let conversation = viewModel[indexPath.row] else { return }
        delegate?.archivedListViewController(self, didSelectConversation: conversation)
    }
}

// MARK: - CollectionViewDataSource

extension ArchivedListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! ConversationListCell
        cell.conversation = viewModel[indexPath.row]
        cell.delegate = self
        cell.mutuallyExclusiveSwipeIdentifier = swipeIdentifier
        cell.autoresizingMask = .flexibleWidth
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layoutCell.size(inCollectionViewSize: collectionView.bounds.size)
    }

}

// MARK: - ArchivedListViewModelDelegate

extension ArchivedListViewController: ArchivedListViewModelDelegate {
    func archivedListViewModel(_ model: ArchivedListViewModel, didUpdateArchivedConversationsWithChange change: ConversationListChangeInfo, applyChangesClosure: @escaping () -> Void) {
        applyChangesClosure()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func archivedListViewModel(_ model: ArchivedListViewModel, didUpdateConversationWithChange change: ConversationChangeInfo) {

        // no-op, ConversationListCell extended ZMConversationObserver 
    }

}

// MARK: - ConversationListCellDelegate

extension ArchivedListViewController: ConversationListCellDelegate {
    func indexPath(for cell: ConversationListCell) -> IndexPath? {
        return collectionView.indexPath(for: cell)
    }

    func conversationListCellJoinCallButtonTapped(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else { return }

        startCallController = ConversationCallController(conversation: conversation, target: self)
        startCallController?.joinCall()
    }

    func conversationListCellOverscrolled(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else { return }

        actionController = ConversationActionController(conversation: conversation, target: self, sourceView: cell)
        actionController?.presentMenu(from: cell, context: .list)
    }

}
