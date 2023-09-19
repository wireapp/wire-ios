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

protocol EmojiPickerViewControllerDelegate: AnyObject {
    func emojiPickerDidSelectEmoji(_ emoji: Emoji)
    func emojiPickerDeleteTapped()
}

final class EmojiKeyboardViewController: UIViewController {

    weak var delegate: EmojiPickerViewControllerDelegate?
    fileprivate var emojiDataSource: EmojiDataSource!
    fileprivate let collectionView = EmojiCollectionView()
    let sectionViewController = EmojiSectionViewController(types: EmojiSectionType.all)

    private var deleting = false

    init() {
        super.init(nibName: nil, bundle: nil)

        emojiDataSource = EmojiDataSource(provider: cellForEmoji)
        collectionView.dataSource = emojiDataSource
        collectionView.delegate = self
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
        view.backgroundColor = SemanticColors.View.backgroundConversationView
        view.addSubview(collectionView)

        addChild(sectionViewController)
        view.addSubview(sectionViewController.view)
        sectionViewController.didMove(toParent: self)
    }

    private func createConstraints() {
        guard let sectionViewControllerView = sectionViewController.view else { return }

        [collectionView, sectionViewControllerView].prepareForLayout()

        let sectionViewControllerViewTrailing = sectionViewControllerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)

        sectionViewControllerViewTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: sectionViewControllerView.topAnchor),
            sectionViewControllerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UIScreen.safeArea.bottom),
            sectionViewControllerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sectionViewControllerViewTrailing,
            sectionViewControllerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        ])
    }

    func cellForEmoji(_ emoji: Emoji, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: EmojiCollectionViewCell.zm_reuseIdentifier, for: indexPath) as! EmojiCollectionViewCell
        cell.titleLabel.text = emoji.value
        return cell
    }

    func updateSectionSelection() {
        let minSection = Set(self.collectionView.indexPathsForVisibleItems.map { $0.section }).min()
        guard let section = minSection  else { return }
        self.sectionViewController.didSelectSection(self.emojiDataSource[section].id)
    }

    @objc func backspaceTapped(_ sender: IconButton) {
        delete()
    }

    @objc func backspaceLongPressed(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            deleting = true
            delete()
        default: deleting = false
        }
    }

    func delete() {
        delegate?.emojiPickerDeleteTapped()
        guard deleting else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.delete()
        }
    }

}

extension EmojiKeyboardViewController: EmojiSectionViewControllerDelegate {

    func sectionViewControllerDidSelectType(_ type: EmojiSectionType, scrolling: Bool) {
        guard let section = emojiDataSource.sectionIndex(for: type) else { return }
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: !scrolling)
    }

}

extension EmojiKeyboardViewController: UICollectionViewDelegateFlowLayout {

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

final class EmojiCollectionViewCell: UICollectionViewCell {

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.6 : 1
            }
        }
    }

    var isCurrent: Bool = false {
        didSet {
            guard isCurrent else {
                layer.borderColor = UIColor.clear.cgColor
                backgroundColor = .clear

                return
            }

            layer.borderWidth = 1.0
            layer.cornerRadius = 12.0
            backgroundColor = SemanticColors.Button.reactionBackgroundSelected
            layer.borderColor = SemanticColors.Button.reactionBorderSelected.cgColor
        }
    }

    func setupViews() {
        titleLabel.textAlignment = .center
        let fontSize: CGFloat =  UIDevice.current.userInterfaceIdiom == .pad ? 40 : 28
        titleLabel.font = .systemFont(ofSize: fontSize)
        titleLabel.adjustsFontSizeToFitWidth = true
        addSubview(titleLabel)
    }

    private func createConstraints() {
        [titleLabel].prepareForLayout()
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }

}

final class EmojiCollectionView: UICollectionView {

    private let layout = UICollectionViewFlowLayout()

    init() {
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
        EmojiCollectionViewCell.register(in: self)
        setupLayout()
        contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = contentSize.height / 5
        layout.itemSize = CGSize(width: size, height: size)
    }

    func setupLayout() {
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
