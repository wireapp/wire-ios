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


@objc
public enum TabBarStyle : UInt {
    case Default, Light, Dark, Colored
}


public protocol TabBarDelegate : class {
    
    func didSelectIndex(index: Int)
    
}

@objc
public class TabBar: UIView {
    
    public private(set) var style : TabBarStyle
    public private(set) var items : [UITabBarItem] = []
    public private(set) var selectedIndex : Int {
        didSet {
            updateArrowPosition()
            updateButtonSelection()
        }
    }
    public weak var delegate : TabBarDelegate?
    
    private var selectedButton : UIButton {
        get {
            return self.buttonRow.subviews[selectedIndex] as! UIButton
        }
    }
    
    private let buttonRow : UIView
    private let leftLineView : UIView
    private let rightLineView : UIView
    private let arrowView : UIImageView
    private var arrowPosition : NSLayoutConstraint! = nil
    
    required public init(items: [UITabBarItem], style: TabBarStyle, selectedIndex: Int = 0) {
        
        assert(items.count > 0, "TabBar must be initialized with at least one item")
        
        self.items = items
        self.selectedIndex = selectedIndex
        self.leftLineView = UIView()
        self.rightLineView = UIView()
        self.arrowView = UIImageView()
        self.buttonRow = UIView()
        self.style = style
        
        super.init(frame: CGRectZero)
        
        setupViews()
        createConstraints()
        updateButtonSelection()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        for button in items.map(self.itemButton) {
            self.buttonRow.addSubview(button)
        }
        
        let lineColor = self.style == .Colored ? UIColor.whiteColor() : ColorScheme.defaultColorScheme().colorWithName(ColorSchemeColorSeparator, variant: colorSchemeVariant())
        self.arrowView.image = WireStyleKit.imageOfTabWithColor(lineColor)
        self.leftLineView.backgroundColor = lineColor
        self.rightLineView.backgroundColor = lineColor
        
        self.addSubview(self.buttonRow)
        self.addSubview(self.leftLineView)
        self.addSubview(self.rightLineView)
        self.addSubview(self.arrowView)
    }
    
    private func createConstraints() {
        
        constrain(buttonRow.subviews.first!) { firstButton in
            firstButton.leading == firstButton.superview!.leading
        }
        
        constrain(buttonRow.subviews.last!) { lastButton in
            lastButton.trailing == lastButton.superview!.trailing
        }
        
        for button in buttonRow.subviews {
            constrain(button) { button in
                button.top == button.superview!.top
                button.bottom == button.superview!.bottom
            }
        }
        
        var previous = buttonRow.subviews.first!
        for current in buttonRow.subviews.dropFirst() {
            constrain(previous, current) { previous, current in
                previous.trailing == current.leading
                previous.width == current.width
            }
            previous = current
        }
        
        constrain(self.buttonRow) { buttonRow in
            buttonRow.top == buttonRow.superview!.top
            buttonRow.left >= buttonRow.superview!.left
            buttonRow.right <= buttonRow.superview!.right
            buttonRow.centerX == buttonRow.superview!.centerX
            buttonRow.height == 40
            buttonRow.width == 375 ~ 750
        }
        
        constrain(self.leftLineView, self.buttonRow, self.arrowView) { leftLineView, buttonRow, arrowView in
            leftLineView.height == 1
            leftLineView.top == buttonRow.bottom
            leftLineView.left == leftLineView.superview!.left
            leftLineView.right == arrowView.left
            leftLineView.bottom == leftLineView.superview!.bottom
        }
        
        constrain(self.rightLineView, self.buttonRow, self.arrowView) { rightLineView, buttonRow, arrowView in
            rightLineView.height == 1
            rightLineView.top == buttonRow.bottom
            rightLineView.left == arrowView.right
            rightLineView.right == rightLineView.superview!.right
            rightLineView.bottom == rightLineView.superview!.bottom
        }
        
        constrain(self.arrowView, self.selectedButton) { arrowView, selectedButton in
            arrowView.bottom == arrowView.superview!.bottom
            self.arrowPosition = arrowView.centerX == selectedButton.centerX
        }
    }
    
    private func updateButtonSelection() {
        for view in self.buttonRow.subviews {
            if let button = view as? Button {
                button.selected = false
            }
        }
        
        self.selectedButton.selected = true
    }
    
    private func updateArrowPosition() {
        self.removeConstraint(self.arrowPosition)
        
        constrain(self.arrowView, self.selectedButton) { arrowView, selectedButton in
            self.arrowPosition = arrowView.centerX == selectedButton.centerX
        }
    }
    
    private func itemButton (item: UITabBarItem) -> Button {
        let button = Button.init(type: .Custom)
        button.textTransform = .Upper
        button.setTitle(item.title, forState: .Normal)
        button.addTarget(self, action: #selector(TabBar.itemSelected(_:)), forControlEvents: .TouchUpInside)
        button.cas_styleClass = styleClass()
        return button
    }
    
    func setSelectedIndex( index: Int, animated: Bool) {
        if (animated) {
            UIView.animateWithDuration(0.35) {
                self.selectedIndex = index
                self.layoutIfNeeded()
            }
        } else {
            self.selectedIndex = index
            self.layoutIfNeeded()
        }
    }
    
    /// MARK - Styling
    
    private func styleClass() -> String {
        switch (self.style) {
        case .Default:
            return "tab"
        case .Light:
            return "tab-light"
        case .Dark:
            return "tab-dark"
        case .Colored:
            return "tab-monochrome"
        }
    }
    
    private func colorSchemeVariant() -> ColorSchemeVariant {
        switch (self.style) {
        case .Light:
            return .Light
        case .Dark:
            return .Dark
        default:
            return ColorScheme.defaultColorScheme().variant
        }
    }
    
    /// MARK - Actions
    
    func itemSelected(sender: AnyObject) {
        guard
            let button = sender as? UIButton,
            let selectedIndex =  self.buttonRow.subviews.indexOf(button)
        else {
            return
        }
        
        self.delegate?.didSelectIndex(selectedIndex)
        setSelectedIndex(selectedIndex, animated: true)
    }
}
