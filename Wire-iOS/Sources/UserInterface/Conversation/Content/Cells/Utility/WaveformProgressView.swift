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


import UIKit
import Cartography

private class WaveformBarsView: UIView {
    
    var samples : [NSNumber] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var barColor : UIColor = UIColor.grayColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.contentMode = .Redraw;
    }
    
    override private func drawRect(rect: CGRect) {
        guard let c = UIGraphicsGetCurrentContext()  else { return }
        
        CGContextClearRect(c, self.bounds);
        self.backgroundColor?.setFill();
        CGContextFillRect(c, rect);
        
        if samples.isEmpty {
            return
        }
        
        let barWidth : CGFloat = 2
        let minHeight : CGFloat = 1
        let barspacing : CGFloat = 1
        let stepSpacing = barWidth + barspacing
        let numbersOfBars = Int((rect.width + barspacing) / stepSpacing)
        
        for i in 0..<numbersOfBars {
            let loudness = samples[Int((Float(i) / Float(numbersOfBars)) * Float(samples.count))].floatValue
            let rect = CGRectMake(CGFloat(i) * stepSpacing, rect.height / 2, barWidth, max(minHeight, rect.height * CGFloat(loudness) * 0.5))
            CGContextAddRect(c, rect)
        }
        
        let bars = CGContextCopyPath(c)
        
        CGContextTranslateCTM(c, 0, rect.height)
        CGContextScaleCTM(c, 1, -1)
        CGContextAddPath(c, bars)
        
        barColor.setFill()
        CGContextFillPath(c)
    }
}

public class WaveformProgressView: UIView {
    
    private let backgroundWaveform = WaveformBarsView()
    private let foregroundWaveform = WaveformBarsView()
    private var maskShape = CAShapeLayer()
    
    public var samples : [NSNumber] = [] {
        didSet {
            backgroundWaveform.samples = samples
            foregroundWaveform.samples = samples
        }
    }
    
    public var barColor : UIColor = UIColor.grayColor() {
        didSet {
            backgroundWaveform.barColor = barColor
        }
    }
    
    public var highlightedBarColor : UIColor = UIColor.accentColor() {
        didSet {
            foregroundWaveform.barColor = highlightedBarColor
        }
    }
    
    public var progress : Float = 0.0 {
        didSet {
            setProgress(progress, animated: false)
        }
    }
    
    public override var backgroundColor: UIColor? {
        didSet {
            backgroundWaveform.backgroundColor = backgroundColor
            foregroundWaveform.backgroundColor = backgroundColor
        }
    }
    
    public func setProgress(progress: Float, animated: Bool) {
        let path = UIBezierPath(rect: CGRectMake(0, 0, self.bounds.width * CGFloat(progress), self.bounds.height)).CGPath
        
        if (animated) {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = maskShape.path
            animation.toValue = path
            animation.duration = 0.25
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            animation.fillMode = kCAFillModeForwards
            maskShape.addAnimation(animation, forKey: animation.keyPath)
        }
        
        maskShape.path = path
    }
    
    public override var bounds: CGRect {
        didSet {
            maskShape.path = UIBezierPath(rect: CGRectMake(0, 0, self.bounds.width * CGFloat(progress), self.bounds.height)).CGPath
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        maskShape.fillColor = UIColor.whiteColor().CGColor
        backgroundWaveform.backgroundColor = UIColor.clearColor()
        backgroundWaveform.barColor = UIColor.grayColor()
        backgroundWaveform.translatesAutoresizingMaskIntoConstraints = false
        foregroundWaveform.backgroundColor = UIColor.clearColor()
        foregroundWaveform.barColor = UIColor.accentColor()
        foregroundWaveform.translatesAutoresizingMaskIntoConstraints = false
        foregroundWaveform.layer.mask = maskShape
        
        addSubview(backgroundWaveform)
        addSubview(foregroundWaveform)
        
        constrain(backgroundWaveform, foregroundWaveform) { backgroundWaveform, foregroundWaveform in
            backgroundWaveform.edges == backgroundWaveform.superview!.edges
            foregroundWaveform.edges == backgroundWaveform.superview!.edges
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
