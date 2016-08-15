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
import Classy
import WireExtensionComponents

extension UIView {
    
    static var debugColors: [UIColor] {
        return [
            .redColor(),
            .blackColor(),
            .darkGrayColor(),
            .grayColor(),
            .redColor(),
            .greenColor(),
            .blueColor(),
            .cyanColor(),
            .yellowColor(),
            .magentaColor(),
            .orangeColor(),
            .purpleColor(),
            .brownColor()
            ]
    }
    
    func debug(startIndex: Int? = nil) {
        var index = startIndex ?? 0

        subviews.forEach { view in
            view.layer.borderWidth = 1
            let color = UIView.debugColors[index]
            view.layer.borderColor = color.colorWithAlphaComponent(0.2).CGColor
            view.backgroundColor = color.colorWithAlphaComponent(0.02)
            index = index == UIView.debugColors.count - 1 ? 0 : index + 1
            view.debug(index)
        }
    }
}


@objc public enum InputBarState: UInt {
    case Writing, Editing
}

private struct InputBarConstants {
    let buttonsBarHeight: CGFloat = 56
    let contentLeftMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.left_margin"))
    let contentRightMargin = CGFloat(WAZUIMagic.floatForIdentifier("content.right_margin"))
}

@objc public class InputBar: UIView {
    
    public let textView: TextView = ResizingTextView()
    public let leftAccessoryView  = UIView()
    public let rightAccessoryView = UIView()
    public let buttonRow: InputBarButtonsView
    public let buttonContainer = UIView()
    public let buttonBox = UIView()
    public let editingRow = InputBarEditView()
    
    public var editingBackgroundColor: UIColor?
    public var barBackgroundColor: UIColor?

    private var contentSizeObserver: NSObject? = nil
    private var rowTopInsetConstraint: NSLayoutConstraint? = nil
    
    private let fakeCursor = UIView()
    private let inputBarSeparator = UIView()
    private let buttonRowSeparator = UIView()
    private let constants = InputBarConstants()
    private let notificationCenter = NSNotificationCenter.defaultCenter()
    
    public var inputbarState: InputBarState = .Writing {
        didSet {
            updateInputBar(withState: inputbarState)
        }
    }
    
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
        notificationCenter.removeObserver(self)
        contentSizeObserver = nil
    }

    required public init(buttons: [UIButton]) {
        buttonRow = InputBarButtonsView(buttons: buttons)
        super.init(frame: CGRectZero)
                
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        addGestureRecognizer(tapGestureRecognizer)
        buttonRow.clipsToBounds = true
        buttonBox.clipsToBounds = true
        
        [leftAccessoryView, textView, rightAccessoryView, inputBarSeparator, buttonBox, buttonRowSeparator].forEach(addSubview)
        buttonBox.addSubview(buttonContainer)
        [buttonRow, editingRow].forEach(buttonContainer.addSubview)
        textView.addSubview(fakeCursor)
        CASStyler.defaultStyler().styleItem(self)

        setupViews()
        createConstraints()
        updateTopSeparator()

        notificationCenter.addObserver(self, selector: #selector(textViewTextDidChange), name: UITextViewTextDidChangeNotification, object: textView)
        notificationCenter.addObserver(self, selector: #selector(textViewDidBeginEditing), name: UITextViewTextDidBeginEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(textViewDidEndEditing), name: UITextViewTextDidEndEditingNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
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
        textView.textContainerInset = UIEdgeInsetsMake(17, 0, 17, constants.contentRightMargin)
        textView.placeholderTextContainerInset = UIEdgeInsetsMake(21, 10, 21, 0)
        textView.keyboardType = .Default;
        textView.returnKeyType = .Send;
        textView.keyboardAppearance = ColorScheme.defaultColorScheme().keyboardAppearance;
        textView.placeholderTextTransform = .Upper
        
        contentSizeObserver = KeyValueObserver.observeObject(textView, keyPath: "contentSize", target: self, selector: #selector(textViewContentSizeDidChange))
        updateBackgroundColor()
    }
    
    private func createConstraints() {
        
        constrain(buttonBox, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView) { buttonRow, textView, buttonRowSeparator, leftAccessoryView, rightAccessoryView in
            leftAccessoryView.leading == leftAccessoryView.superview!.leading
            leftAccessoryView.top == leftAccessoryView.superview!.top
            leftAccessoryView.bottom == buttonRow.top
            leftAccessoryView.width == constants.contentLeftMargin
            
            rightAccessoryView.trailing == rightAccessoryView.superview!.trailing - 16
            rightAccessoryView.top == rightAccessoryView.superview!.top
            rightAccessoryView.bottom == buttonRow.top
            
            buttonRow.top == textView.bottom
            textView.top == textView.superview!.top
            textView.leading == leftAccessoryView.trailing
            textView.trailing == textView.superview!.trailing
            textView.height >= 56
            textView.height <= 120 ~ 750

            buttonRowSeparator.top == buttonRow.top
            buttonRowSeparator.left == buttonRowSeparator.superview!.left + 16
            buttonRowSeparator.right == buttonRowSeparator.superview!.right - 16
            buttonRowSeparator.height == 0.5
        }
        
        constrain(editingRow, buttonRow, buttonContainer) { editRow, buttonRow, container in
            editRow.top == container.top
            editRow.leading == container.leading
            editRow.trailing == container.trailing
            editRow.bottom == buttonRow.top
            editRow.height == constants.buttonsBarHeight
            
            buttonRow.leading == container.leading
            buttonRow.trailing == container.trailing
            buttonRow.bottom == container.bottom
        }
        
        constrain(buttonBox, buttonContainer)  { buttonBox, container in
            buttonBox.bottom == buttonBox.superview!.bottom
            buttonBox.left == buttonBox.superview!.left
            buttonBox.right <= buttonBox.superview!.right
            buttonBox.height == constants.buttonsBarHeight
            buttonBox.width == 414 ~ 750

            container.leading == buttonBox.leading
            container.trailing == buttonBox.trailing
            self.rowTopInsetConstraint = container.top == buttonBox.top - constants.buttonsBarHeight
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
    
    @objc private func didTapBackground(gestureRecognizer: UITapGestureRecognizer!) {
        guard gestureRecognizer.state == .Recognized else { return }
        buttonRow.showRow(0, animated: true)
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
                let locationInButtonRow = self.buttonContainer.convertPoint(point, fromView: self)
                return locationInButtonRow.y < self.buttonContainer.bounds.size.height / 1.3
            }
            else {
                return false
            }
        }
        else {
            return super.pointInside(point, withEvent: event)
        }
    }
    
    // MARK: - InputBarState
    
    public func setEditingWithText(text: String) {
        inputbarState = .Editing
        textView.text = text
    }
    
    func updateInputBar(withState state: InputBarState) {
        if state == .Writing {
            textView.text = nil
        } else {
            textView.becomeFirstResponder()
        }

        updateEditViewState()
        rowTopInsetConstraint?.constant = state == .Writing ? -constants.buttonsBarHeight : 0
        UIView.wr_animateWithEasing(RBBEasingFunctionEaseInOutExpo, duration: 0.35, animations: layoutIfNeeded) { _ in
            UIView.animateWithDuration(0.2) {
                self.updateBackgroundColor()
            }
        }
    }
    
    func backgroundColor(forInputBarState state: InputBarState) -> UIColor? {
        guard let writingColor = barBackgroundColor, editingColor = editingBackgroundColor else { return nil }
        let mixed = writingColor.mix(editingColor, amount: 0.16)
        return state == .Editing ? mixed : writingColor
    }
    
    func updateBackgroundColor() {
        backgroundColor = backgroundColor(forInputBarState: inputbarState)
    }
    
    // MARK: – Editing View State
    
    public func undo() {
        guard inputbarState == .Editing else { return }
        guard let undoManager = textView.undoManager where undoManager.canUndo else { return }
        undoManager.undo()
        updateEditViewState()
    }
    
    func updateEditViewState() {
        guard inputbarState == .Editing else { return }
        let hasChanges = textView.undoManager?.canUndo ?? false
        editingRow.undoButton.enabled = hasChanges
        editingRow.confirmButton.enabled = hasChanges
    }
    
}

extension InputBar {

    func textViewTextDidChange(notification: NSNotification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }
    
    func textViewDidBeginEditing(notification: NSNotification) {
        updateFakeCursorVisibility(notification.object as? UIResponder)
        updateEditViewState()
    }
    
    func textViewDidEndEditing(notification: NSNotification) {
        updateFakeCursorVisibility()
        updateEditViewState()
    }

}

extension InputBar {
    func applicationDidBecomeActive(notification: NSNotification) {
        startCursorBlinkAnimation()
    }
}
