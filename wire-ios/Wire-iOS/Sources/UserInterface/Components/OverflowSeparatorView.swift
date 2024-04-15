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

import Foundation
import UIKit

final class OverflowSeparatorView: UIView {

    var inverse: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.applyStyle()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func applyStyle() {
        self.backgroundColor = SemanticColors.View.backgroundSeparatorCell
        self.alpha = 0
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: .hairline)
    }

    func scrollViewDidScroll(scrollView: UIScrollView!) {
        if inverse {
            let (height, contentHeight) = (scrollView.bounds.height, scrollView.contentSize.height)
            let offsetY = scrollView.contentOffset.y
            let showSeparator = contentHeight - offsetY > height
            alpha = showSeparator ? 1 : 0
        } else {
            self.alpha = scrollView.contentOffset.y > 0 ? 1 : 0
        }
    }
}
