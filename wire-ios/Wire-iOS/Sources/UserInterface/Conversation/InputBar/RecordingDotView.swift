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

final class RecordingDotView: UIView {
    // MARK: Lifecycle

    // MARK: - Init

    init() {
        super.init(frame: CGRect.zero)

        backgroundColor = SemanticColors.Icon.foregroundDefaultRed
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    var animating = false {
        didSet {
            if oldValue == animating {
                return
            }

            if animating {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    // MARK: - Override Methods

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }

    // MARK: Fileprivate

    fileprivate func stopAnimation() {
        layer.removeAllAnimations()
        alpha = 1
    }

    // MARK: Private

    // MARK: - Methods

    private func startAnimation() {
        alpha = 0
        delay(0.15) {
            UIView.animate(withDuration: 0.55, delay: 0, options: [.autoreverse, .repeat], animations: {
                self.alpha = 1
            })
        }
    }
}
