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

/// This class is a drop-in replacement for UILabel which can be copied.
final class CopyableLabel: UILabel {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressed)))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        action == #selector(copy(_:))
    }

    override func copy(_: Any?) {
        UIPasteboard.general.string = text
    }

    // MARK: Private

    private let dimmedAlpha: CGFloat = 0.4
    private let dimmAnimationDuration: TimeInterval = 0.33

    @objc
    private func longPressed(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began,
              let view = recognizer.view,
              let superview = view.superview,
              view == self,
              becomeFirstResponder() else {
            return
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuDidHide),
            name: UIMenuController.didHideMenuNotification,
            object: nil
        )
        UIMenuController.shared.showMenu(from: superview, rect: view.frame)
        fade(dimmed: true)
    }

    @objc
    private func menuDidHide(_: Notification) {
        NotificationCenter.default.removeObserver(self, name: UIMenuController.didHideMenuNotification, object: nil)
        fade(dimmed: false)
    }

    private func fade(dimmed: Bool) {
        UIView.animate(withDuration: dimmAnimationDuration) {
            self.alpha = dimmed ? self.dimmedAlpha : 1
        }
    }
}
