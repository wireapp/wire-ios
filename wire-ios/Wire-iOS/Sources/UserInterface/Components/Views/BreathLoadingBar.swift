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

import QuartzCore
import UIKit

// MARK: - BreathLoadingBarDelegate

protocol BreathLoadingBarDelegate: AnyObject {
    func animationDidStarted()
    func animationDidStopped()
}

// MARK: - BreathLoadingBar

final class BreathLoadingBar: UIView {
    weak var delegate: BreathLoadingBarDelegate?

    private(set) lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 0)

    var animating = false {
        didSet {
            guard animating != oldValue else { return }

            if animating {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }

    var state: NetworkStatusViewState = .online {
        didSet {
            if oldValue != state {
                updateView()
            }
        }
    }

    private let BreathLoadingAnimationKey = "breathLoadingAnimation"

    var animationDuration: TimeInterval = 0.0

    var isAnimationRunning: Bool {
        layer.animation(forKey: BreathLoadingAnimationKey) != nil
    }

    init(animationDuration duration: TimeInterval) {
        self.animating = false

        super.init(frame: .zero)
        layer.cornerRadius = CGFloat.SyncBar.cornerRadius

        self.animationDuration = duration

        createConstraints()
        updateView()

        backgroundColor = UIColor.accent()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateView() {
        switch state {
        case .online:
            heightConstraint.constant = 0
            alpha = 0
            layer.cornerRadius = 0

        case .onlineSynchronizing:
            heightConstraint.constant = CGFloat.SyncBar.height
            alpha = 1
            layer.cornerRadius = CGFloat.SyncBar.cornerRadius

            backgroundColor = UIColor.accent()

        case .offlineExpanded:
            heightConstraint.constant = CGFloat.OfflineBar.expandedHeight
            alpha = 0
            layer.cornerRadius = CGFloat.OfflineBar.cornerRadius
        }

        layoutIfNeeded()
    }

    private func createConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightConstraint,
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // restart animation
        if animating {
            startAnimation()
        }
    }

    @objc
    func applicationDidBecomeActive(_: Any) {
        if animating, !isAnimationRunning {
            startAnimation()
        }
    }

    @objc
    func applicationDidEnterBackground(_: Any) {
        if animating {
            stopAnimation()
        }
    }

    func startAnimation() {
        delegate?.animationDidStarted()

        let anim = CAKeyframeAnimation(keyPath: "opacity")
        anim.values = [CGFloat.SyncBar.minOpacity, CGFloat.SyncBar.maxOpacity, CGFloat.SyncBar.minOpacity]
        anim.isRemovedOnCompletion = false
        anim.autoreverses = false
        anim.fillMode = .forwards
        anim.repeatCount = .infinity
        anim.duration = animationDuration
        anim.timingFunction = EasingFunction.easeInOutSine.timingFunction
        layer.add(anim, forKey: BreathLoadingAnimationKey)
    }

    func stopAnimation() {
        delegate?.animationDidStopped()

        layer.removeAnimation(forKey: BreathLoadingAnimationKey)
    }

    static func withDefaultAnimationDuration() -> BreathLoadingBar {
        BreathLoadingBar(animationDuration: TimeInterval.SyncBar.defaultAnimationDuration)
    }
}
