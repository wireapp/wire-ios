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

final class DestructionCountdownView: UIView {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSublayers()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    typealias IconColors = SemanticColors.Icon

    // MARK: - Animation

    var isAnimatingProgress: Bool {
        elapsedTimeLayer.animation(forKey: elapsedTimeAnimationKey) != nil
    }

    var remainingTimeColor: UIColor? {
        get {
            remainingTimeLayer.fillColor.flatMap(UIColor.init)
        }
        set {
            remainingTimeLayer.fillColor = newValue?.cgColor
        }
    }

    var elapsedTimeColor: UIColor? {
        get {
            elapsedTimeLayer.strokeColor.flatMap(UIColor.init)
        }
        set {
            elapsedTimeLayer.strokeColor = newValue?.withAlphaComponent(1).cgColor
            elapsedTimeLayer.opacity = Float(newValue?.alpha ?? CGFloat(0))
        }
    }

    // MARK: - Layout

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        let backgroundFrame = bounds
        let borderWidth = 0.10 * backgroundFrame.width
        let elapsedFrame = bounds.insetBy(dx: borderWidth, dy: borderWidth)

        elapsedTimeLayer.frame = backgroundFrame
        elapsedTimeLayer.path = makePath(for: elapsedFrame)
        elapsedTimeLayer.fillColor = nil
        elapsedTimeLayer.lineWidth = min(elapsedFrame.width, elapsedFrame.height) / 2

        remainingTimeLayer.frame = backgroundFrame
        remainingTimeLayer.path = CGPath(ellipseIn: bounds, transform: nil)
    }

    func startAnimating(duration: TimeInterval, currentProgress: CGFloat) {
        let elapsedTimeAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        elapsedTimeAnimation.duration = duration
        elapsedTimeAnimation.fromValue = currentProgress
        elapsedTimeAnimation.toValue = 1
        elapsedTimeAnimation.fillMode = .forwards
        elapsedTimeAnimation.isRemovedOnCompletion = false

        elapsedTimeLayer.add(elapsedTimeAnimation, forKey: elapsedTimeAnimationKey)
    }

    func stopAnimating() {
        elapsedTimeLayer.removeAllAnimations()
    }

    func setProgress(_ newValue: CGFloat) {
        elapsedTimeLayer.strokeEnd = newValue
    }

    // MARK: Private

    private let remainingTimeLayer = CAShapeLayer()
    private let elapsedTimeLayer = CAShapeLayer()
    private let elapsedTimeAnimationKey = "elapsedTime"

    private func configureSublayers() {
        layer.addSublayer(remainingTimeLayer)
        layer.addSublayer(elapsedTimeLayer)

        elapsedTimeLayer.strokeEnd = 0
        elapsedTimeLayer.isOpaque = false
        remainingTimeLayer.isOpaque = false

        elapsedTimeColor = IconColors.foregroundElapsedTimeSelfDeletingMessage

        remainingTimeColor = IconColors.foregroundRemainingTimeSelfDeletingMessage
    }

    private func makePath(for bounds: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.addArc(
            center: CGPoint(
                x: bounds.midX,
                y: bounds.midY
            ),
            radius: min(
                bounds.height,
                bounds.width
            ) / 4,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: false
        )
        return path
    }
}
