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

@objc public class ProgressView: UIView {
    private var deterministic: Bool? = .None
    private var progress: Float = 0
    private var progressView: UIView = UIView()
    private var spinner: GapLoadingBar = GapLoadingBar(gapSize: 80, animationDuration: 3.0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.progressView.autoresizingMask = [.FlexibleHeight, .FlexibleRightMargin]
        self.spinner.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        self.progressView.frame = self.bounds
        self.spinner.frame = self.bounds
        
        self.addSubview(self.progressView)
        self.addSubview(self.spinner)
        
        self.updateForStateAnimated(false)
        self.updateProgress(false)
        self.progressView.backgroundColor = self.tintColor
        self.spinner.backgroundColor = self.tintColor
    }
    
    public override var tintColor: UIColor? {
        didSet {
            self.progressView.backgroundColor = tintColor
            self.spinner.backgroundColor = tintColor
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateProgress(false)
    }
    
    public func setDeterministic(determenistic: Bool, animated: Bool) {
        if self.deterministic != .None && self.deterministic == determenistic {
            return
        }
        self.deterministic = determenistic
        self.updateForStateAnimated(animated)
        self.updateProgress(animated)
    }

    public func setProgress(progress: Float, animated: Bool) {
        self.progress = progress
        self.updateProgress(animated)
    }

    private func updateProgress(animated: Bool) {
        let progress = (self.deterministic ?? false) ? self.progress : 1;
        
        let setBlock = {
            self.progressView.frame = CGRectMake(0, 0, CGFloat(progress) * self.bounds.size.width, self.bounds.size.height)
        }
        
        if animated {
            UIView.animateWithDuration(0.35, delay: 0.0, options: [.BeginFromCurrentState], animations: setBlock, completion: .None)
        }
        else {
            setBlock()
        }
    }
    
    private func updateForStateAnimated(animated: Bool) {
        if let det = self.deterministic where det {
            self.progressView.hidden = false
            self.spinner.hidden = true
            self.spinner.animating = false
        }
        else {
            self.progressView.hidden = true
            self.spinner.hidden = false
            self.spinner.animating = true
        }
    }
}
