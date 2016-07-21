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

public class ConversationTitleView: UIView {
    
    var titleColor, titleColorSelected: UIColor?
    var titleFont: UIFont?
    var titleButton: UIButton!
    public var tapHandler: (UIButton -> Void)? = nil
    
    init(conversation: ZMConversation) {
        super.init(frame: CGRectZero)
        createViews(conversation)
        CASStyler.defaultStyler().styleItem(self)
        configure(conversation)
        frame = titleButton.bounds
        createConstraints()
    }
    
    func createViews(conversation: ZMConversation) {
        titleButton = UIButton()
        titleButton.addTarget(self, action: #selector(ConversationTitleView.titleButtonTapped(_:)), forControlEvents: .TouchUpInside)
        addSubview(titleButton)
    }
    
    func configure(conversation: ZMConversation) {
        guard let font = titleFont, color = titleColor, selectedColor = titleColorSelected else { return }
        let title = conversation.displayName.uppercaseString && font
        
        let titleWithColor: UIColor -> NSAttributedString = {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(forIcon: .DownArrow, fontSize: 8, color: $0)
            return (title + "  " + NSAttributedString(attachment: attachment)) && $0
        }
        
        titleButton.setAttributedTitle(titleWithColor(color), forState: .Normal)
        titleButton.setAttributedTitle(titleWithColor(selectedColor), forState: .Highlighted)
        titleButton.sizeToFit()
    }
    
    func createConstraints() {
        constrain(self, titleButton) { view, button in
            button.edges == view.edges
        }
    }
    
    func titleButtonTapped(sender: UIButton) {
        tapHandler?(sender)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
