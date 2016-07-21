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
import TTTAttributedLabel

class ConversationIgnoredDeviceCell : IconSystemCell {
    private static let deviceListLink = NSURL(string:"setting://device-list")!
    
    override func configureForMessage(message: ZMConversationMessage!, layoutProperties: ConversationCellLayoutProperties!) {
        super.configureForMessage(message, layoutProperties: layoutProperties)
        
        self.leftIconView.image = WireStyleKit.imageOfShieldnotverified()
        
        self.updateLabel()
    }
    
    func updateLabel() {
        if let systemMessageData = message.systemMessageData,
            let labelFont = self.labelFont,
            let labelBoldFont = self.labelBoldFont,
            let labelTextColor = self.labelTextColor
            where systemMessageData.systemMessageType == ZMSystemMessageType.IgnoredClient && systemMessageData.users.count > 0 {
                
                guard let user = systemMessageData.users.first else { return }
                
                let youString = "content.system.you_started".localized.uppercaseString
                let deviceString : String
                
                if user.isSelfUser {
                    deviceString = "content.system.your_devices".localized.uppercaseString
                } else {
                    deviceString = String(format: "content.system.other_devices".localized, user.displayName).uppercaseString
                }
                
                let baseString = "content.system.unverified".localized
                let endResult = String(format: baseString, youString, deviceString).uppercaseString

                let youRange = (endResult as NSString).rangeOfString(youString)
                let deviceRange = (endResult as NSString).rangeOfString(deviceString)

                let attributedString = NSMutableAttributedString(string: endResult)
                attributedString.addAttributes([NSFontAttributeName: labelFont, NSForegroundColorAttributeName: labelTextColor], range:NSRange(location: 0, length: endResult.characters.count))
                attributedString.addAttributes([NSFontAttributeName: labelBoldFont, NSForegroundColorAttributeName: labelTextColor], range: youRange)
                attributedString.addAttributes([NSFontAttributeName: labelFont, NSLinkAttributeName: self.dynamicType.deviceListLink], range: deviceRange)
                
                self.labelView.attributedText = attributedString
                self.labelView.addLinks()
                self.labelView.accessibilityLabel = self.labelView.attributedText.string
        }
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL URL: NSURL!) {
        if URL.isEqual(self.dynamicType.deviceListLink) {
            if let systemMessageData = message.systemMessageData,
                let users = systemMessageData.users,
                let firstUserClient = users.first
            {
                ZClientViewController.sharedZClientViewController().openClientListScreenForUser(firstUserClient)
            }
        }
    }

}
