//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCommonComponents

final class CompleteReactionPickerViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: EmojiPickerViewControllerDelegate?
    private var emojiDataSource: EmojiDataSource!
    private let collectionView = ReactionsCollectionView()
    private let sectionViewController: ReactionSectionViewController
    private let topBar = ModalTopBar()
    private let searchBar = UISearchBar()
    private let selectedReactions: Set<Emoji>

    private var deleting = false

    // MARK: - Init

    init(selectedReactions: Set<Emoji>) {
        self.selectedReactions = selectedReactions
        let hasNoRecentlyUsedReactions =  RecentlyUsedEmojiPeristenceCoordinator.loadOrCreate().emojis.isEmpty
        let sectionTypes: [EmojiSectionType] = hasNoRecentlyUsedReactions ? EmojiSectionType.basicTypes : EmojiSectionType.all
        sectionViewController = ReactionSectionViewController(types: sectionTypes)
        super.init(nibName: nil, bundle: nil)

        emojiDataSource = EmojiDataSource(provider: cellForEmoji)
        collectionView.dataSource = emojiDataSource
        collectionView.delegate = self
        searchBar.delegate = self
        sectionViewController.sectionDelegate = self
        setupViews()
        createConstraints()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredContentSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSectionSelection()
    }

    // MARK: - Setup views and constraints

    func setupViews() {
        typealias Strings = L10n.Localizable.Content.Reactions
        view.addSubview(topBar)
        topBar.delegate = self
        topBar.needsSeparator = false
        topBar.backgroundColor = SemanticColors.View.backgroundDefault
        topBar.configure(title: Strings.title, subtitle: nil, topAnchor: safeTopAnchor)

        addChild(sectionViewController)
        view.addSubview(sectionViewController.view)
        sectionViewController.didMove(toParent: self)

        searchBar.backgroundImage = UIImage()
        searchBar.searchTextField.backgroundColor = SemanticColors.View.backgroundDefaultWhite
        searchBar.placeholder = Strings.search
        view.addSubview(searchBar)
        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(collectionView)

        collectionView.keyboardDismissMode = .onDrag

        setupAccessibility()
    }

    private func createConstraints() {
        guard let sectionViewControllerView = sectionViewController.view else { return }

        [topBar, searchBar, collectionView, sectionViewControllerView].prepareForLayout()

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeTopAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),

            searchBar.topAnchor.constraint(equalTo: topBar.safeBottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 10.0),
            searchBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -10.0),

            sectionViewControllerView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: -8.0),
            sectionViewControllerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 10.0),
            sectionViewControllerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -10.0),
            sectionViewControllerView.heightAnchor.constraint(equalToConstant: 44.0),

            collectionView.topAnchor.constraint(equalTo: sectionViewControllerView.safeBottomAnchor, constant: 18.0),
            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeBottomAnchor)
        ])
    }

    // MARK: - Collection View

    func cellForEmoji(_ emoji: Emoji, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.zm_reuseIdentifier, for: indexPath) as! EmojiCollectionViewCell
        cell.titleLabel.text = emoji.value
        cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        cell.isCurrent = selectedReactions.contains(emoji)
        return cell
    }

    func updateSectionSelection() {
        let minSection = Set(self.collectionView.indexPathsForVisibleItems.map { $0.section }).min()
        guard let section = minSection  else { return }
        self.sectionViewController.didSelectSection(self.emojiDataSource[section].type)
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        typealias ReactionPickerAccessibility = L10n.Accessibility.ReactionPicker
        searchBar.isAccessibilityElement = true
        topBar.dismissButton.isAccessibilityElement = true
        topBar.dismissButton.accessibilityValue = ReactionPickerAccessibility.DismissButton.description

        if searchBar.placeholder != nil {
            searchBar.accessibilityValue = ReactionPickerAccessibility.SearchFieldPlaceholder.description
        }
    }

    // MARK: - Dynamic Type

    @objc
    func preferredContentSizeChanged(_ notification: Notification) {
        collectionView.reloadData()
    }
}

// MARK: - EmojiSectionViewControllerDelegate

extension CompleteReactionPickerViewController: EmojiSectionViewControllerDelegate {

    func sectionViewControllerDidSelectType(_ type: EmojiSectionType, scrolling: Bool) {
        guard let section = emojiDataSource.sectionIndex(for: type) else { return }
        let indexPath = IndexPath(item: 0, section: section)
        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            collectionView.setContentOffset(
                CGPoint(x: collectionView.contentOffset.x, y: attributes.frame.minY),
                animated: !scrolling)
        } else {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: !scrolling)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CompleteReactionPickerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let emoji = emojiDataSource[indexPath]
        delegate?.emojiPickerDidSelectEmoji(emoji)
        emojiDataSource.register(used: emoji)
    }

    func scrollViewDidScroll(_ scrolLView: UIScrollView) {
        updateSectionSelection()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 30.0, left: 0.0, bottom: 0.0, right: 0.0)
    }
}

// MARK: - ModalTopBarDelegate

extension CompleteReactionPickerViewController: ModalTopBarDelegate {
    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension CompleteReactionPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        emojiDataSource.filterEmojis(withQuery: searchText)
        collectionView.reloadData()
    }
}
