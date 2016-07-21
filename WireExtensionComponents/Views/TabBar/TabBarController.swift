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



@objc protocol TabBarControllerDelegate: class {
    func tabBarController(controller: TabBarController, tabBarDidSelectIndex: Int)
}


public extension UIViewController {
    public var wr_tabBarController : TabBarController? {
        get {
            if (parentViewController == nil) {
                return nil;
            }
            else if (parentViewController?.isKindOfClass(TabBarController) != nil) {
                return parentViewController as? TabBarController;
            }
            else {
                return parentViewController?.wr_tabBarController;
            }
        }
    }
    
    @objc public func takeFirstResponder() {
        // no-op
    }
}


@objc
public class TabBarController: UIViewController {

    public private(set) var viewControllers : [UIViewController]
    public private(set) var selectedIndex : Int
    public var style : TabBarStyle = .Default
    public var enabled : Bool = true {
        didSet {
            self.tabBar?.userInteractionEnabled = self.enabled
        }
    }
    
    weak var delegate: TabBarControllerDelegate?
    
    private var presentedTabBarViewController : UIViewController?
    private var tabBar : TabBar?
    private var contentView : UIView!
    
    required public init( viewControllers: [UIViewController]) {
        self.viewControllers = viewControllers
        self.selectedIndex = 0
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        createViews()
        createConstraints()
        selectIndex(selectedIndex, animated: false)
    }
    
    private func createViews() {
        self.contentView = UIView(frame: self.view.bounds)
        self.contentView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.contentView)
        
        if self.viewControllers.count > 1 {
            let items = self.viewControllers.map({ viewController in viewController.tabBarItem! })
            self.tabBar = TabBar(items: items, style: self.style, selectedIndex: selectedIndex)
            self.tabBar?.delegate = self
            self.tabBar?.userInteractionEnabled = self.enabled
            self.view.addSubview(self.tabBar!)
        }
    }
    
    private func createConstraints() {
        
        if let tabBar = self.tabBar {
            constrain(tabBar, self.contentView) { tabBar, contentView in
                tabBar.top == tabBar.superview!.top
                tabBar.left == tabBar.superview!.left
                tabBar.right == tabBar.superview!.right
                contentView.top == tabBar.bottom
            }
        }
        
        constrain(self.contentView) { contentView in
            if (self.tabBar == nil) { contentView.top == contentView.superview!.top }
            contentView.left == contentView.superview!.left
            contentView.right == contentView.superview!.right
            contentView.bottom == contentView.superview!.bottom
        }
    }
        
    public func selectIndex(index: Int, animated: Bool) {
        selectedIndex = index
        
        let toViewController = self.viewControllers[index]
        let fromViewController = self.presentedTabBarViewController
        
        if toViewController == fromViewController || self.contentView == nil{
            return
        }
        
        delegate?.tabBarController(self, tabBarDidSelectIndex: index)
        self.presentedTabBarViewController = toViewController
        self.tabBar?.setSelectedIndex(index, animated: animated)
        
        if (fromViewController != nil) {
            fromViewController?.willMoveToParentViewController(nil)
        }
        
        toViewController.view.translatesAutoresizingMaskIntoConstraints = true
        toViewController.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        toViewController.view.frame = self.contentView.bounds
        
        if (animated && fromViewController != nil) {
            fromViewController?.willMoveToParentViewController(nil)
            addChildViewController(toViewController)
            
            self.transitionFromViewController(fromViewController!, toViewController: toViewController, duration: 0.35, options: .TransitionCrossDissolve, animations: {
                if toViewController.respondsToSelector(#selector(UIViewController.takeFirstResponder)) {
                    toViewController.performSelector(#selector(UIViewController.takeFirstResponder))
                }
                }, completion: { (finished) in
                    fromViewController?.removeFromParentViewController()
                    toViewController.didMoveToParentViewController(self)
                }
            )
        } else {
            fromViewController?.removeFromParentViewController()
            addChildViewController(toViewController)
            self.contentView.addSubview(toViewController.view)
            toViewController.didMoveToParentViewController(self)
        }
    }
    
}

extension TabBarController : TabBarDelegate {
    
    public func didSelectIndex(index: Int) {
        selectIndex(index, animated: true)
    }
    
}
