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


private let RequestsAvailableNotificationName = "RequestsAvailableNotification"


@objc(ZMRequestAvailableObserver) public protocol RequestAvailableObserver : NSObjectProtocol {
    
    func newRequestsAvailable()
    
}

/// ZMRequestAvailableNotification is used by request strategies to signal the operation loop that
/// there are new potential requests available to process.
@objc(ZMRequestAvailableNotification) public class RequestAvailableNotification : NSObject {
    
    public static func notifyNewRequestsAvailable(sender: NSObjectProtocol) {
        NSNotificationCenter.defaultCenter().postNotificationName(RequestsAvailableNotificationName, object: sender)
    }
    
    public static func addObserver(observer: RequestAvailableObserver) {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: Selector(observer.newRequestsAvailable()), name: RequestsAvailableNotificationName, object: nil)
    }
    
    public static func removeObserver(observer: RequestAvailableObserver) {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: RequestsAvailableNotificationName, object: nil)
    }
    
}
