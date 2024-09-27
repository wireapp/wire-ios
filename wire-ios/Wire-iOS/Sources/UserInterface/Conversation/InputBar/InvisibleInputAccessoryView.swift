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

// MARK: - InvisibleInputAccessoryViewDelegate

// Because the system manages the input accessory view lifecycle and positioning, we have to monitor what
// is being done to us and report back

protocol InvisibleInputAccessoryViewDelegate: AnyObject {
    func invisibleInputAccessoryView(
        _ invisibleInputAccessoryView: InvisibleInputAccessoryView,
        superviewFrameChanged frame: CGRect?
    )
}

// MARK: - InvisibleInputAccessoryView

final class InvisibleInputAccessoryView: UIView {
    weak var delegate: InvisibleInputAccessoryViewDelegate?
    private var frameObserver: NSKeyValueObservation?

    var overriddenIntrinsicContentSize: CGSize = .zero {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        overriddenIntrinsicContentSize
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            frameObserver = superview!.observe(
                \UIView.center,
                options: []
            ) { [weak self] _, _ in
                self?.superviewFrameChanged()
            }
        } else {
            frameObserver = nil
        }
    }

    private func superviewFrameChanged() {
        delegate?.invisibleInputAccessoryView(self, superviewFrameChanged: superview?.frame)
    }
}
