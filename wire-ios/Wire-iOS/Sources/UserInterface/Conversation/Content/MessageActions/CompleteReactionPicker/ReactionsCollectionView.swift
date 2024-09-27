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
import WireDesign
import WireFoundation

// MARK: - ReactionsCollectionView

final class ReactionsCollectionView: UICollectionView {
    private let layout = UICollectionViewFlowLayout()

    init() {
        super.init(frame: .zero, collectionViewLayout: layout)
        backgroundColor = SemanticColors.View.backgroundDefaultWhite
        showsHorizontalScrollIndicator = false
        EmojiCollectionViewCell.register(in: self)
        setupLayout()
        configureObservers()
        contentInset = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ReactionsCollectionView {
    private func setupLayout() {
        let currentDevice = DeviceWrapper(device: .current)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = currentDevice.userInterfaceIdiom == .pad ? 7 : 7
        layout.minimumInteritemSpacing = currentDevice.userInterfaceIdiom == .pad ? 12 : 7
        let itemSize = currentDevice.userInterfaceIdiom == .pad ? 51 : 41
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
    }

    private func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardPresentation),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardPresentation),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc
    private func handleKeyboardPresentation(notification: Notification) {
        let keyboardHeight = UIView.keyboardFrame(in: self, forKeyboardNotification: notification).height

        contentInset = UIEdgeInsets(
            top: 10.0,
            left: 30.0,
            bottom: 10.0 + keyboardHeight,
            right: 30.0
        )
    }
}
