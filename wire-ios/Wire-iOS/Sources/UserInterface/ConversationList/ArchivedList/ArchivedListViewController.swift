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
import WireFoundation
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

final class ArchivedListViewController: UIViewController {

    private var collectionView: UICollectionView!
    private let cellReuseIdentifier = "ConversationListCellArchivedIdentifier"
    private let swipeIdentifier = "ArchivedList"
    private let viewModel: ArchivedListViewModel
    private let layoutCell = ConversationListCell()
    private var actionController: ConversationActionController?
    private var startCallController: ConversationCallController?
    private let userSession: UserSession

    weak var delegate: ArchivedListViewControllerDelegate?

    init(userSession: UserSession) {
        self.userSession = userSession
        viewModel = ArchivedListViewModel(userSession: userSession)
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityViewIsModal = true
        view.backgroundColor = SemanticColors.View.backgroundConversationList
        setupNavigationItem()
        setupCollectionView()
        setupEmptyPlaceholder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func setupNavigationItem() {

        let titleLabel = UILabel()
        titleLabel.text = L10n.Localizable.ArchivedList.title.capitalized
        titleLabel.font = FontSpec(.normal, .semibold).font
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.accessibilityTraits = .header
        navigationItem.titleView = titleLabel

        let dismissButton = IconButton()
        dismissButton.setIcon(.cross, size: .tiny, for: [])
        dismissButton.addAction(
            .init { [weak self] _ in self?.delegate?.archivedListViewControllerWantsToDismiss(self!) },
            for: .primaryActionTriggered
        )
        dismissButton.accessibilityIdentifier = "archiveCloseButton"
        dismissButton.accessibilityLabel = L10n.Localizable.General.close
        dismissButton.setIconColor(SemanticColors.Label.textDefault, for: .normal)
        navigationItem.rightBarButtonItem = .init(customView: dismissButton)
    }

    private func setupCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ConversationListCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.alwaysBounceVertical = true
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.accessibilityIdentifier = "archived conversation list"
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }

    private func setupEmptyPlaceholder() {

        let titleLabel = DynamicFontLabel(
            text: L10n.Localizable.ArchivedList.EmptyPlaceholder.headline + " 👻",
            style: .h3,
            color: SemanticColors.Label.textDefault
        )
        titleLabel.textAlignment = .center

        let descriptionLabel = DynamicFontLabel(
            text: L10n.Localizable.ArchivedList.EmptyPlaceholder.subheadline,
            style: .body1,
            color: SemanticColors.Label.baseSecondaryText
        )
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([

            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            stackView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            stackView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1),

            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272)
        ])
        stackView.isHidden = !viewModel.isEmptyArchivePlaceholderVisible
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

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
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

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return layoutCell.size(inCollectionViewSize: collectionView.bounds.size)
    }
}

// MARK: - ArchivedListViewModelDelegate

extension ArchivedListViewController: ArchivedListViewModelDelegate {

    func archivedListViewModel(
        _ model: ArchivedListViewModel,
        didUpdateArchivedConversationsWithChange change: ConversationListChangeInfo,
        applyChangesClosure: @escaping () -> Void
    ) {
        applyChangesClosure()
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func archivedListViewModel(
        _ model: ArchivedListViewModel,
        didUpdateConversationWithChange change: ConversationChangeInfo
    ) {
        // no-op, ConversationListCell extended ZMConversationObserver
    }
}

// MARK: - ConversationListCellDelegate

extension ArchivedListViewController: ConversationListCellDelegate {

    func indexPath(for cell: ConversationListCell) -> IndexPath? {
        collectionView.indexPath(for: cell)
    }

    func conversationListCellJoinCallButtonTapped(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else { return }

        startCallController = ConversationCallController(conversation: conversation, target: self)
        startCallController?.joinCall()
    }

    func conversationListCellOverscrolled(_ cell: ConversationListCell) {
        guard let conversation = cell.conversation as? ZMConversation else { return }

        actionController = ConversationActionController(
            conversation: conversation,
            target: self,
            sourceView: cell,
            userSession: userSession
        )
        actionController?.presentMenu(from: cell, context: .list)
    }
}
