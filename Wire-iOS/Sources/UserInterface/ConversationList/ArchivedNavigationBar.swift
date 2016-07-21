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


@objc final class ArchivedNavigationBar: UIView {
    
    let separatorView = UIView()
    let titleLabel = UILabel()
    let dismissButton = IconButton()
    let barHeight: CGFloat = 44

    var dismissButtonHandler: dispatch_block_t?
    
    var showSeparator: Bool = false {
        didSet {
            separatorView.fadeAndHide(!showSeparator)
        }
    }
    
    convenience init(title: String) {
        self.init(frame: CGRectZero)
        titleLabel.text = title
        createViews()
        createConstraints()
    }
    
    func createViews() {
        separatorView.hidden = true
        dismissButton.setIcon(.Cancel, withSize: .Tiny, forState: .Normal)
        dismissButton.addTarget(self, action: #selector(ArchivedNavigationBar.dismissButtonTapped(_:)), forControlEvents: .TouchUpInside)
        dismissButton.accessibilityIdentifier = "archiveCloseButton"
        [titleLabel, dismissButton, separatorView].forEach(addSubview)
    }
    
    func createConstraints() {
        constrain(self, separatorView, titleLabel, dismissButton) { view, separator, title, button in
            separator.height == 0.5
            separator.left == view.left
            separator.right == view.right
            separator.bottom == view.bottom
            
            title.center == view.center
            
            button.centerY == view.centerY
            button.right == view.right - 16
            button.left >= title.right + 8
        }
    }
    
    func dismissButtonTapped(sender: IconButton) {
        dismissButtonHandler?()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: barHeight)
    }
    
}
