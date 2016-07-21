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
import WireExtensionComponents


@objc
public class InputBar: UIView {
    
    public let textView: TextView = ResizingTextView()
    public let leftAccessoryView  = UIView()
    public let rightAccessoryView = UIView()
    public let buttonRow = UIView()
    public let buttonRowBox = UIView()
    private(set) var multilineLayout: Bool = false
    
    private let minimumButtonWidthIPhone5: CGFloat = 53
    private let minimumButtonWidth: CGFloat = 56
    private let buttonsBarHeight: CGFloat = 56
    
    private(set) var currentRow: UInt = 0
    private var buttonRowTopInset: NSLayoutConstraint!
    private var buttonRowHeight: NSLayoutConstraint!
    private let expandRowButton = IconButton()
    private var lastLayoutWidth: CGFloat = 0
    
    private let fakeCursor = UIView()
    private let inputBarSeparator = UIView()
    private let buttonRowSeparator = UIView()
    private var contentSizeObserver: NSObject? = nil
    private var textObserver: NSObject? = nil
    private let buttons: [UIButton]
    
    private let contentLeftMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin"))
    private let contentRightMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin"))
    private let iconSize = UIImage.sizeForZetaIconSize(.Tiny)
    private let buttonMargin = (CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin")) / 2) - (UIImage.sizeForZetaIconSize(.Tiny) / 2)
    
    private var textIsOverflowing = false {
        didSet {
            updateTopSeparator()
        }
    }
    
    public var separatorEnabled = false {
        didSet {
            updateTopSeparator()
        }
    }
    
    public var invisibleInputAccessoryView : InvisibleInputAccessoryView? = nil  {
        didSet {
            textView.inputAccessoryView = invisibleInputAccessoryView
        }
    }
    
    override public var bounds: CGRect {
        didSet {
            invisibleInputAccessoryView?.setIntrinsicContentSize(CGSizeMake(UIViewNoIntrinsicMetric, bounds.height))
        }
    }
        
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        startCursorBlinkAnimation()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        contentSizeObserver = nil
        textObserver = nil
    }

    required public init(buttons: [UIButton]) {
        self.buttons = buttons
        
        super.init(frame: CGRectZero)
        
        self.buttons.forEach { button in
            button.addTarget(self, action: #selector(InputBar.anyButtonPressed(_:)), forControlEvents: .TouchUpInside)
        }
                
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(InputBar.didTapBackground(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)
        
        self.expandRowButton.accessibilityIdentifier = "showOtherRowButton"
        self.expandRowButton.setIcon(.Elipsis, withSize: .Tiny, forState: .Normal)
        self.expandRowButton.addTarget(self, action: #selector(InputBar.elipsisButtonPressed(_:)), forControlEvents: .TouchUpInside)
        
        self.buttonRowBox.clipsToBounds = true
        
        [leftAccessoryView, textView, rightAccessoryView, inputBarSeparator, buttonRowBox, buttonRowSeparator].forEach(self.addSubview)
        self.buttonRowBox.addSubview(self.buttonRow)
        self.buttonRow.addSubview(expandRowButton)
        textView.addSubview(fakeCursor)
        
        for button in buttons {
            buttonRow.addSubview(button)
        }
        
        setupViews()
        createConstraints()
        updateTopSeparator()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InputBar.textViewDidBeginEditing(_:)), name: UITextViewTextDidBeginEditingNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InputBar.textViewDidEndEditing(_:)), name: UITextViewTextDidEndEditingNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(InputBar.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        fakeCursor.backgroundColor = UIColor.accentColor()
        
        buttonRowSeparator.cas_styleClass = "separator"
        inputBarSeparator.cas_styleClass = "separator"
        
        textView.accessibilityIdentifier = "inputField"
        textView.placeholder = "conversation.input_bar.placeholder".localized
        textView.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsetsMake(17, 0, 17, contentRightMargin)
        textView.placeholderTextContainerInset = UIEdgeInsetsMake(21, 10, 21, 0)
        textView.keyboardType = .Default;
        textView.returnKeyType = .Send;
        textView.keyboardAppearance = ColorScheme.defaultColorScheme().keyboardAppearance;
        textView.placeholderTextTransform = .Upper
        
        contentSizeObserver = KeyValueObserver.observeObject(textView, keyPath: "contentSize", target: self, selector: #selector(InputBar.textViewContentSizeDidChange(_:)))
        textObserver = KeyValueObserver.observeObject(textView, keyPath: "text", target: self, selector: #selector(InputBar.textViewTextDidChange(_:)))
    }
    
    private func setupButtonInsets(buttons: [UIButton], rowIsFull: Bool) {
        let titleTopMargin: CGFloat = 10
        
        let firstButton = buttons.first!
        let firstButtonLabelSize = firstButton.titleLabel?.intrinsicContentSize()
        let firstTitleMargin = (contentLeftMargin / 2) - iconSize - ((firstButtonLabelSize?.width)! / 2)
        firstButton.contentHorizontalAlignment = .Left
        firstButton.imageEdgeInsets = UIEdgeInsetsMake(0, buttonMargin, 0, 0)
        firstButton.titleEdgeInsets = UIEdgeInsetsMake(iconSize + (firstButtonLabelSize?.height)! + titleTopMargin, firstTitleMargin, 0, 0)
        
        if rowIsFull {
            let lastButton = buttons.last!
            let lastButtonLabelSize = lastButton.titleLabel?.intrinsicContentSize()
            let lastTitleMargin = (contentLeftMargin / 2.0) - ((lastButtonLabelSize?.width)! / 2.0)
            lastButton.contentHorizontalAlignment = .Right
            lastButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, buttonMargin - (lastButtonLabelSize?.width)!)
            lastButton.titleEdgeInsets = UIEdgeInsetsMake(iconSize + (lastButtonLabelSize?.height)! + titleTopMargin, 0, 0, lastTitleMargin - 1)
            lastButton.titleLabel?.lineBreakMode = .ByClipping
        }
        
        for button in buttons.dropFirst().dropLast() {
            let buttonLabelSize = button.titleLabel?.intrinsicContentSize()
            button.contentHorizontalAlignment = .Center
            button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -(buttonLabelSize?.width)!)
            button.titleEdgeInsets = UIEdgeInsetsMake(iconSize + (buttonLabelSize?.height)! + titleTopMargin, -iconSize, 0, 0)
        }
    }
    
    private func createConstraints() {
        
        constrain(buttonRowBox, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView) { buttonRowBox, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView in
            leftAccessoryView.leading == leftAccessoryView.superview!.leading
            leftAccessoryView.top == leftAccessoryView.superview!.top
            leftAccessoryView.bottom == buttonRowBox.top
            leftAccessoryView.width == contentLeftMargin
            
            rightAccessoryView.trailing == rightAccessoryView.superview!.trailing - 16
            rightAccessoryView.top == rightAccessoryView.superview!.top
            rightAccessoryView.bottom == buttonRowBox.top
            
            buttonRowBox.top == textView.bottom
            textView.top == textView.superview!.top
            textView.leading == leftAccessoryView.trailing
            textView.trailing == textView.superview!.trailing
            textView.height >= 56
            textView.height <= 120 ~ 750

            buttonRowSeparator.top == buttonRowBox.top
            buttonRowSeparator.left == buttonRowSeparator.superview!.left + 16
            buttonRowSeparator.right == buttonRowSeparator.superview!.right - 16
            buttonRowSeparator.height == 0.5
        }
        
        constrain(buttonRow, buttonRowBox)  { buttonRow, buttonRowBox in
            
            self.buttonRowTopInset = buttonRowBox.top == buttonRow.top
            buttonRow.left == buttonRowBox.left
            buttonRow.right == buttonRowBox.right
            buttonRowHeight = buttonRow.height == 0
            
            buttonRowBox.bottom == buttonRowBox.superview!.bottom
            buttonRowBox.left == buttonRowBox.superview!.left
            buttonRowBox.right <= buttonRowBox.superview!.right
            buttonRowBox.height == self.buttonsBarHeight
            buttonRowBox.width == 414 ~ 750
        }
        
        constrain(inputBarSeparator) { inputBarSeparator in
            inputBarSeparator.top == inputBarSeparator.superview!.top
            inputBarSeparator.leading == inputBarSeparator.superview!.leading
            inputBarSeparator.trailing == inputBarSeparator.superview!.trailing
            inputBarSeparator.height == 0.5
        }
        
        constrain(fakeCursor) { fakeCursor in
            fakeCursor.width == 2
            fakeCursor.height == 23
            fakeCursor.centerY == fakeCursor.superview!.centerY
            fakeCursor.leading == fakeCursor.superview!.leading
        }
    }
    
    private func layoutAndConstrainButtonRows() {
        
        guard self.bounds.size.width > 0 else {
            return
        }
        
        // drop existing constraints
        for button in buttons {
            button.removeFromSuperview()
            buttonRow.addSubview(button)
        }
        
        let minimumButtonWidth = self.bounds.size.width <= 320 ? self.minimumButtonWidthIPhone5 : self.minimumButtonWidth
        
        let numberOfButtons = Int(floorf(Float(self.bounds.size.width / minimumButtonWidth)))
        self.multilineLayout = numberOfButtons < self.buttons.count

        let firstRowButtons: [UIButton]
        let secondRowButtons: [UIButton]
        
        if self.multilineLayout {
            firstRowButtons = self.buttons.prefix(numberOfButtons - 1) + [self.expandRowButton]
            secondRowButtons = Array<UIButton>(self.buttons.suffix(self.buttons.count - (numberOfButtons - 1)))
            self.buttonRowHeight.constant = self.buttonsBarHeight * 2
        }
        else {
            firstRowButtons = self.buttons
            secondRowButtons = []
            self.buttonRowHeight.constant = self.buttonsBarHeight
        }

        self.constrainRowOfButtons(firstRowButtons, inset: 0, rowIsFull: true, referenceButton: .None)
        
        if (secondRowButtons.count > 0) {
            self.constrainRowOfButtons(secondRowButtons, inset: self.buttonsBarHeight, rowIsFull: secondRowButtons.count == numberOfButtons, referenceButton: firstRowButtons[1])
        }
    }
    
    private func constrainRowOfButtons(rowOfButtons: [UIButton], inset: CGFloat, rowIsFull: Bool, referenceButton: UIButton?) {
        constrain(rowOfButtons.first!) { firstButton in
            firstButton.leading == firstButton.superview!.leading
        }
        
        if rowIsFull {
            constrain(rowOfButtons.last!) { lastButton in
                lastButton.trailing == lastButton.superview!.trailing
            }
        }
        
        for button in rowOfButtons {
            
            if button == self.expandRowButton {
                constrain(button, self, self.buttonRowBox) { button, currentView, buttonRowBox in
                    button.top == buttonRowBox.top
                    button.height == self.buttonsBarHeight
                }
            }
            else {
                constrain(button, self) { button, currentView in
                    button.top == button.superview!.top + inset
                    button.height == self.buttonsBarHeight
                }
            }
        }
        
        var previous = rowOfButtons.first!
        for current in rowOfButtons.dropFirst() {
            let isFirstButton = previous == rowOfButtons.first
            let isLastButton = rowIsFull && current == rowOfButtons.last
            
            
            constrain(previous, current) { previous, current in
                previous.trailing == current.leading
                
                if (isFirstButton) {
                    previous.width == current.width * 0.5 + iconSize / 2 + buttonMargin
                } else if (isLastButton) {
                    current.width == previous.width * 0.5 + iconSize / 2 + buttonMargin
                } else {
                    current.width == previous.width
                }
            }
            previous = current
        }
        
        if let reference = referenceButton where !rowIsFull {
            constrain(reference, rowOfButtons.last!) { reference, lastButton in
                lastButton.width == reference.width
            }
        }
        
        setupButtonInsets(rowOfButtons, rowIsFull: rowIsFull)
    }
    
    @objc private func anyButtonPressed(button: UIButton!) {
        self.showRow(0, animated: true)
    }
    
    @objc private func elipsisButtonPressed(button: UIButton!) {
        if self.currentRow == 0 {
            self.showRow(1, animated: true)
        }
        else {
            self.showRow(0, animated: true)
        }
    }
    
    @objc private func didTapBackground(gestureRecognizer: UITapGestureRecognizer!) {
        if gestureRecognizer.state == .Recognized {
            self.showRow(0, animated: true)
        }
    }
    
    public func showRow(rowIndex: UInt, animated: Bool) {
        if rowIndex == currentRow {
            return
        }
        
        self.currentRow = rowIndex
        let change = {
            self.buttonRowTopInset.constant = CGFloat(rowIndex) * self.buttonsBarHeight
            self.layoutIfNeeded()
        }
        
        if animated {
            UIView.wr_animateWithEasing(RBBEasingFunctionEaseInOutExpo, duration: 0.35, animations: change)
        }
        else {
            change()
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds.size.width != self.lastLayoutWidth {
            
            self.layoutAndConstrainButtonRows()
            
            self.lastLayoutWidth = self.bounds.size.width
        }
    }
    
    private func startCursorBlinkAnimation() {
        if fakeCursor.layer.animationForKey("blinkAnimation") == nil {
            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [1, 1, 0, 0]
            animation.keyTimes = [0, 0.4, 0.7, 0.9]
            animation.duration = 0.64
            animation.autoreverses = true
            animation.repeatCount = FLT_MAX
            
            fakeCursor.layer.addAnimation(animation, forKey: "blinkAnimation")
        }
    }
    
    private func updateTopSeparator() {
        inputBarSeparator.hidden = !textIsOverflowing && !separatorEnabled
    }
    
    private func updateFakeCursorVisibility(firstReponder: UIResponder? = nil) {
        fakeCursor.hidden = textView.isFirstResponder() || textView.text.characters.count != 0 || firstReponder != nil
    }
    
    func textViewContentSizeDidChange(notification: NSNotification) {
        textIsOverflowing = textView.contentSize.height > textView.bounds.size.height
    }

    // MARK: - Disable interaction on lower part of buttons not to interfer with keyboard
    
    override public func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if self.textView.isFirstResponder() {
            if super.pointInside(point, withEvent: event) {
                let locationInButtonRow = self.buttonRowBox.convertPoint(point, fromView: self)
                return locationInButtonRow.y < self.buttonRowBox.bounds.size.height / 1.3
            }
            else {
                return false
            }
        }
        else {
            return super.pointInside(point, withEvent: event)
        }
    }
}

extension InputBar {
    
    func textViewTextDidChange(notification: NSNotification) {
        updateFakeCursorVisibility()
    }
    
    func textViewDidBeginEditing(notification: NSNotification) {
        updateFakeCursorVisibility(notification.object as? UIResponder)
    }
    
    func textViewDidEndEditing(notification: NSNotification) {
        updateFakeCursorVisibility()
    }
    
}

extension InputBar {
    func applicationDidBecomeActive(notification: NSNotification) {
        startCursorBlinkAnimation()
    }
}
