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

final class ZMProgressView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: Internal

    override var tintColor: UIColor? {
        didSet {
            progressView.backgroundColor = tintColor
            spinner.backgroundColor = tintColor
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgress(false)
    }

    func setDeterministic(_ determenistic: Bool, animated: Bool) {
        if deterministic != .none, deterministic == determenistic {
            return
        }
        deterministic = determenistic
        updateForStateAnimated(animated)
        updateProgress(animated)
    }

    func setProgress(_ progress: Float, animated: Bool) {
        self.progress = progress
        updateProgress(animated)
    }

    // MARK: Fileprivate

    fileprivate var deterministic: Bool? = .none
    fileprivate var progress: Float = 0
    fileprivate var progressView = UIView()
    fileprivate var spinner = BreathLoadingBar(animationDuration: 3.0)

    fileprivate func setup() {
        progressView.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        spinner.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        progressView.frame = bounds
        spinner.frame = bounds

        addSubview(progressView)
        addSubview(spinner)

        updateForStateAnimated(false)
        updateProgress(false)
        progressView.backgroundColor = tintColor
        spinner.backgroundColor = tintColor
    }

    fileprivate func updateProgress(_ animated: Bool) {
        guard self.progress.isNormal,
              bounds.width != 0,
              bounds.height != 0 else {
            return
        }

        let progress = (deterministic ?? false) ? progress : 1

        let setBlock = {
            self.progressView.frame = CGRect(
                x: 0,
                y: 0,
                width: CGFloat(progress) * self.bounds.size.width,
                height: self.bounds.size.height
            )
        }

        if animated {
            UIView.animate(
                withDuration: 0.35,
                delay: 0.0,
                options: [.beginFromCurrentState],
                animations: setBlock,
                completion: .none
            )
        } else {
            setBlock()
        }
    }

    fileprivate func updateForStateAnimated(_: Bool) {
        if let det = deterministic, det {
            progressView.isHidden = false
            spinner.isHidden = true
            spinner.animating = false
        } else {
            progressView.isHidden = true
            spinner.isHidden = false
            spinner.animating = true
        }
    }
}
