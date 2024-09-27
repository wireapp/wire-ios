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

// MARK: - CollectionViewCellAdapter

final class CollectionViewCellAdapter: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var wrappedView: UIView? {
        didSet {
            guard wrappedView != oldValue else {
                return
            }

            contentView.subviews.forEach { $0.removeFromSuperview() }

            guard let wrappedView else {
                return
            }

            wrappedView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(wrappedView)

            NSLayoutConstraint.activate([
                wrappedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                wrappedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                wrappedView.topAnchor.constraint(equalTo: contentView.topAnchor),
                wrappedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }
}

// MARK: - SingleViewSectionController

final class SingleViewSectionController: NSObject, CollectionViewSectionController {
    // MARK: Lifecycle

    init(view: UIView) {
        self.view = view

        super.init()
    }

    // MARK: Internal

    var isHidden: Bool {
        false
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView?.register(
            CollectionViewCellAdapter.self,
            forCellWithReuseIdentifier: CollectionViewCellAdapter.zm_reuseIdentifier
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        view.size(fittingWidth: collectionView.bounds.size.width)

        return view.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: CollectionViewCellAdapter.self, for: indexPath)

        cell.wrappedView = view

        return cell
    }

    // MARK: Fileprivate

    fileprivate var view: UIView
}
