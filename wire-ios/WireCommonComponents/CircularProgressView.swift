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

public class CircularProgressView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupShapeLayer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(CircularProgressView.applicationDidBecomeActive(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func setupShapeLayer() {
        createPath()
        shapeLayer.lineWidth = CGFloat(lineWidth)
        shapeLayer.lineCap = lineCap
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = CGFloat(progress)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = tintColor.cgColor
    }

    override public func didMoveToWindow() {
        updateSpinningAnimation()
    }

    override public var tintColor: UIColor! {
        didSet {
            shapeLayer.strokeColor = tintColor.cgColor
        }
    }

    public var lineCap: CAShapeLayerLineCap = .square {
        didSet {
            setNeedsLayout()
        }
    }

    public var lineWidth: Float = 2 {
        didSet {
            setNeedsLayout()
        }
    }

    public var deterministic = true {
        didSet {
            updateSpinningAnimation()
        }
    }

    private func createPath() {
        shapeLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width / 2).cgPath
    }

    override public class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    var shapeLayer: CAShapeLayer {
        if let shapeLayer = layer as? CAShapeLayer {
            return shapeLayer
        }
        fatalError("shapeLayer is missing: \(layer)")
    }

    private(set) var progress: Float = 0.0

    public func setProgress(_ progress: Float, animated: Bool) {
        self.progress = progress

        if animated {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = shapeLayer.strokeEnd
            stroke.toValue = progress
            stroke.duration = 0.35
            stroke.fillMode = .forwards

            shapeLayer.add(stroke, forKey: nil)
        } else {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = CGFloat(progress)
            shapeLayer.add(stroke, forKey: nil)
        }

        CATransaction.setDisableActions(true)
        shapeLayer.strokeEnd = CGFloat(progress)
        CATransaction.setDisableActions(false)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        setupShapeLayer()
    }

    // MARK: - Spinning animation

    let SpinningAnimationKey = "com.wire.animations.spin"

    private func updateSpinningAnimation() {
        if !deterministic {
            startSpinningAnimation()
        } else {
            stopSpinningAnimation()
        }
    }

    private func startSpinningAnimation() {
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fillMode = .forwards
        rotate.toValue = 2 * CGFloat.pi
        rotate.repeatCount = .infinity
        rotate.duration = 1.0
        rotate.isCumulative = true
        rotate.timingFunction = CAMediaTimingFunction(name: .linear)

        shapeLayer.add(rotate, forKey: SpinningAnimationKey)
    }

    private func stopSpinningAnimation() {
        shapeLayer.removeAnimation(forKey: SpinningAnimationKey)
    }
}

extension CircularProgressView {
    @objc
    func applicationDidBecomeActive(_: Notification) {
        updateSpinningAnimation()
    }
}
