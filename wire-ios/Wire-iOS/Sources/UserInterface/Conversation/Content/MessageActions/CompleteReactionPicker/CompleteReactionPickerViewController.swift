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

class CompleteReactionPickerViewController: UIViewController {

    weak var delegate: EmojiPickerViewControllerDelegate?
    private var emojiDataSource: EmojiDataSource!
    private let collectionView = ReactionsCollectionView()
    private  let sectionViewController = EmojiSectionViewController(types: EmojiSectionType.all)
    private let topBar = ModalTopBar()
    private let searchBar = UISearchBar()

    private var deleting = false

    init() {
        super.init(nibName: nil, bundle: nil)

        emojiDataSource = EmojiDataSource(provider: cellForEmoji)
        collectionView.dataSource = emojiDataSource
        collectionView.delegate = self
        searchBar.delegate = self
        sectionViewController.sectionDelegate = self
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSectionSelection()
    }

    func setupViews() {
        view.addSubview(topBar)
        topBar.delegate = self
        topBar.needsSeparator = false
        topBar.backgroundColor = SemanticColors.View.backgroundDefault
        topBar.configure(title: "Select Reaction", subtitle: nil, topAnchor: safeTopAnchor) //~!@#$%^&*(

        addChild(sectionViewController)
        view.addSubview(sectionViewController.view)
        sectionViewController.didMove(toParent: self)

        searchBar.backgroundColor = SemanticColors.View.backgroundDefault
//        searchBar.colo
        searchBar.placeholder = "Search for Emoji"
        view.addSubview(searchBar)
        view.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(collectionView)
    }

    private func createConstraints() {
        guard let sectionViewControllerView = sectionViewController.view else { return }

        [topBar, searchBar ,collectionView, sectionViewControllerView].prepareForLayout()


        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: safeTopAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),

            searchBar.topAnchor.constraint(equalTo: topBar.safeBottomAnchor, constant: 10.0),
            searchBar.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 10.0),
            searchBar.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -10.0),

            sectionViewControllerView.topAnchor.constraint(equalTo: searchBar.safeBottomAnchor),
            sectionViewControllerView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 10.0),
            sectionViewControllerView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -10.0),
            sectionViewControllerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400.0),


            collectionView.topAnchor.constraint(equalTo: sectionViewControllerView.safeBottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeBottomAnchor)
        ])
    }

    func cellForEmoji(_ emoji: Emoji, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.zm_reuseIdentifier, for: indexPath) as! EmojiCollectionViewCell
        cell.titleLabel.text = emoji
        return cell
    }

    func updateSectionSelection() {
        DispatchQueue.main.async {
            let minSection = Set(self.collectionView.indexPathsForVisibleItems.map { $0.section }).min()
            guard let section = minSection  else { return }
            self.sectionViewController.didSelectSection(self.emojiDataSource[section].type)
        }
    }
}

extension CompleteReactionPickerViewController: EmojiSectionViewControllerDelegate {

    func sectionViewController(_ viewController: EmojiSectionViewController, didSelect type: EmojiSectionType, scrolling: Bool) {
        guard let section = emojiDataSource.sectionIndex(for: type) else { return }
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: !scrolling)
    }

}

extension CompleteReactionPickerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let emoji = emojiDataSource[indexPath]
        delegate?.emojiPickerDidSelectEmoji(emoji)
        guard let result = emojiDataSource.register(used: emoji) else { return }
        collectionView.performBatchUpdates({
            switch result {
            case .insert(let section): collectionView.insertSections(IndexSet(integer: section))
            case .reload(let section): collectionView.reloadSections(IndexSet(integer: section))
            }
        }, completion: { _ in
            self.updateSectionSelection()
        })
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let (first, last) = (section == 0, section == collectionView.numberOfSections)
        return UIEdgeInsets(top: 0, left: !first ? 12 : 0, bottom: 0, right: !last ? 12 : 0)
    }

    func scrollViewDidScroll(_ scrolLView: UIScrollView) {
        updateSectionSelection()
    }
}

extension CompleteReactionPickerViewController: ModalTopBarDelegate {
    func modelTopBarWantsToBeDismissed(_ topBar: ModalTopBar) {
        dismiss(animated: true)
    }
}

extension CompleteReactionPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        emojiDataSource.filterEmojis(withQuery: searchText)
        collectionView.reloadData()
    }
}
