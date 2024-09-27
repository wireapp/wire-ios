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

final class MockPinchGestureRecognizer: UIPinchGestureRecognizer {
    // MARK: Lifecycle

    init(location: CGPoint?, view: UIView?, state: UIGestureRecognizer.State, scale: CGFloat) {
        self.mockLocation = location
        self.mockState = state
        self.mockView = view

        super.init(target: nil, action: nil)
        self.scale = scale
    }

    // MARK: Internal

    let mockState: UIGestureRecognizer.State
    var mockLocation: CGPoint?
    var mockView: UIView?

    override var view: UIView? {
        mockView ?? super.view
    }

    override var state: UIGestureRecognizer.State {
        get { mockState }
        set {}
    }

    override func location(in view: UIView?) -> CGPoint {
        mockLocation ?? super.location(in: view)
    }
}
