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

public final class ProgressSpinner: UIView {

    public var didBecomeActiveNotificationToken: NSObjectProtocol?
    public var didEnterBackgroundNotificationToken: NSObjectProtocol?

    public var color: UIColor = .white {
        didSet {
            updateSpinnerIcon()
        }
    }

    public var iconSize: CGFloat = 32 {
        didSet {
            updateSpinnerIcon()
        }
    }

    public var hidesWhenStopped: Bool = false {
        didSet {
            isHidden = hidesWhenStopped && !isAnimationRunning
        }
    }

    public var isAnimating = false {
        didSet {
            guard oldValue != isAnimating else {
                return
            }

            if isAnimating {
                startAnimationInternal()
            } else {
                stopAnimationInternal()
            }
        }
    }

    private let spinner: UIImageView = .init()

    private var isAnimationRunning: Bool {
        spinner.layer.animation(forKey: "rotateAnimation") != nil
    }

    public init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        createSpinner()
        setupConstraints()

        hidesWhenStopped = true

        didBecomeActiveNotificationToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }

        didEnterBackgroundNotificationToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applicationDidEnterBackground()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        let frame = spinner.layer.frame
        spinner.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        spinner.layer.frame = frame
    }

    override public func didMoveToWindow() {
        if window == nil {
            // CABasicAnimation delegate is strong so we stop all animations when the view is removed.
            stopAnimationInternal()
        } else if isAnimating {
            startAnimationInternal()
        }
    }

    private func createSpinner() {
        spinner.contentMode = .center
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        updateSpinnerIcon()
    }

    override public var intrinsicContentSize: CGSize {
        spinner.image?.size ?? super.intrinsicContentSize
    }

    private func setupConstraints() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func startAnimationInternal() {
        isHidden = false
        stopAnimationInternal()
        if window != nil {
            let animation = ProgressIndicatorRotationAnimation(rotationSpeed: 1.4, beginTime: 0)
            animation.delegate = self
            spinner.layer.add(animation, forKey: "rotateAnimation")
        }
    }

    private func stopAnimationInternal() {
        spinner.layer.removeAllAnimations()
    }

    func updateSpinnerIcon() {
        spinner.image = UIImage.imageForIcon(.spinner, size: iconSize, color: color)
    }

    @objc
    public func startAnimation() {
        isAnimating = true
    }

    @objc
    public func stopAnimation() {
        isAnimating = false
    }

    private func applicationDidBecomeActive() {
        if isAnimating, !isAnimationRunning {
            startAnimationInternal()
        }
    }

    private func applicationDidEnterBackground() {
        if isAnimating {
            stopAnimationInternal()
        }
    }
}

extension ProgressSpinner: CAAnimationDelegate {

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if hidesWhenStopped {
            isHidden = true
        }
    }
}
