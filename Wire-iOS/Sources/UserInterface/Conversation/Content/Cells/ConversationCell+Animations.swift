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


extension ConversationCell {
    
    public func updateVisibleViews(views: [UIView], visibleViews: [UIView], animated: Bool) {
        if (animated) {
            UIView.transitionWithView(self, duration: 0.35, options: .TransitionCrossDissolve, animations: {
                self.updateVisibleViews(views, visibleViews: visibleViews)
                }, completion: nil)
        } else {
            self.updateVisibleViews(views, visibleViews: visibleViews)
        }
    }
    
    public func updateVisibleViews(views: [UIView], visibleViews: [UIView]) {
        let allViews = Set(views)
        let hiddenViews = allViews.subtract(visibleViews)
        
        visibleViews.forEach { $0.hidden = false }
        hiddenViews.forEach { $0.hidden = true }
    }
    
}
