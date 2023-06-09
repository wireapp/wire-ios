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

import Foundation
import UIKit

// MARK: - ReactionCollectionView

final class ReactionCollectionView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {

    // MARK: - Properties

    lazy var collectionViewHeightConstraint: NSLayoutConstraint = collectionView.heightAnchor.constraint(equalToConstant: 40)
    let flowLayout = UICollectionViewFlowLayout()
    private var contentSizeObservation: NSKeyValueObservation?
    private lazy var collectionView: UICollectionView = {
        return UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
    }()

    var reactions = [Reaction]() {
        didSet {
            collectionView.reloadData()
        }
    }

    var contentHeight: CGFloat {
        return collectionView.contentSize.height
    }

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        createCollectionView()
    }

    deinit {
        contentSizeObservation?.invalidate()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createCollectionView() {

        collectionView.register(ReactionCollectionViewCell.self, forCellWithReuseIdentifier: "collectionCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        self.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.fitIn(view: self)

        contentSizeObservation = collectionView.observe(\.contentSize, options: .new, changeHandler: { [weak self] (cell, _) in
            guard let self = self else { return }
            self.collectionViewHeightConstraint.constant = cell.contentSize.height
            self.collectionViewHeightConstraint.isActive = true
        })
    }

    // MARK: - UICollectionView Delegates

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reactions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath as IndexPath) as! ReactionCollectionViewCell
        let reaction = reactions[indexPath.row]
        cell.configureData(
            type: reaction.type.unicodeValue,
            count: reaction.count,
            isToggled: reaction.isSelfUserReacting,
            onToggle: reaction.performReaction

        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 51, height: 24)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }

}
