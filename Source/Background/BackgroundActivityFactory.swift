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
import WireUtilities

@objc open class BackgroundActivityFactory: NSObject {
    
    private static let _instance : BackgroundActivityFactory = BackgroundActivityFactory()
    
    open var application : UIApplication? = nil
    open var mainGroupQueue : ZMSGroupQueue? = nil
    
    @objc open class func sharedInstance() -> BackgroundActivityFactory
    {
        return _instance
    }
    
    @objc open func backgroundActivity(withName name: String) -> ZMBackgroundActivity?
    {
        guard let mainGroupQueue = mainGroupQueue, let application = application else { return nil }
        return ZMBackgroundActivity.begin(withName: name, groupQueue: mainGroupQueue, application: application)
    }
    
    @objc open func backgroundActivity(withName name: String, expirationHandler handler:@escaping ((Void) -> Void)) -> ZMBackgroundActivity?
    {
        guard let mainGroupQueue = mainGroupQueue, let application = application else { return nil }
        return ZMBackgroundActivity.begin(withName: name, groupQueue: mainGroupQueue, expirationHandler: handler, application: application)
    }
    
}
