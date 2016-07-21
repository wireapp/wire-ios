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

@objc public class CircularProgressView: UIView {
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        setupShapeLayer()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CircularProgressView.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    private func setupShapeLayer() {
        self.createPath()
        self.shapeLayer.lineWidth = 2
        self.shapeLayer.lineCap = kCALineCapSquare
        self.shapeLayer.strokeStart = 0.0
        self.shapeLayer.strokeEnd = CGFloat(self.progress)
        self.shapeLayer.fillColor = UIColor.clearColor().CGColor
        self.shapeLayer.strokeColor = self.tintColor.CGColor
    }
    
    override public func didMoveToWindow() {
        updateSpinningAnimation()
    }
    
    override public var tintColor: UIColor! {
        didSet {
            self.shapeLayer.strokeColor = self.tintColor.CGColor
        }
    }
    
    public var deterministic : Bool = true {
        didSet {
            updateSpinningAnimation()
        }
    }
    
    private func createPath() {
        self.shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: CGRectGetWidth(self.bounds)/2).CGPath
    }
    
    override public class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    public var shapeLayer: CAShapeLayer {
        get {
            if let shapeLayer = self.layer as? CAShapeLayer {
                return shapeLayer
            }
            fatalError("shapeLayer is missing: \(self.layer)")
        }
    }
    
    public private(set) var progress : Float = 0.0
        
    public func setProgress(progress: Float, animated: Bool) {
        self.progress = progress
        
        if (animated) {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = self.shapeLayer.strokeEnd
            stroke.toValue = progress
            stroke.duration = 0.35
            stroke.fillMode = kCAFillModeForwards
            
            self.shapeLayer.addAnimation(stroke, forKey: nil)
        } else {
            let stroke = CABasicAnimation(keyPath: "strokeEnd")
            stroke.fromValue = CGFloat(progress)
            self.shapeLayer.addAnimation(stroke, forKey: nil)
        }
        
        CATransaction.setDisableActions(true)
        self.shapeLayer.strokeEnd = CGFloat(progress)
        CATransaction.setDisableActions(false)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.setupShapeLayer()
    }
    
    /// pragma mark - Spinning animation
    
    let SpinningAnimationKey = "com.wire.animations.spin"
    
    private func updateSpinningAnimation() {
        if !deterministic {
            startSpinningAnimation()
        } else {
            stopSpinningAnimation()
        }
    }
    
    private func startSpinningAnimation() {
        let rotate = CABasicAnimation.init(keyPath: "transform.rotation.z")
        rotate.fillMode = kCAFillModeForwards;
        rotate.toValue = 2 * M_PI
        rotate.repeatCount = .infinity
        rotate.duration = 1.0
        rotate.cumulative = true
        rotate.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
        
        self.shapeLayer.addAnimation(rotate, forKey: SpinningAnimationKey);
    }
    
    private func stopSpinningAnimation() {
        self.shapeLayer.removeAnimationForKey(SpinningAnimationKey)
    }
}

extension CircularProgressView {
    func applicationDidBecomeActive(notification : NSNotification) {
        updateSpinningAnimation()
    }
}
