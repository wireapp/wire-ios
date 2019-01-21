//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import WireTransport
import WireTesting

@objcMembers public class FakeReachability: NSObject, ReachabilityProvider, TearDownCapable {
    
    public var observerCount = 0
    public func add(_ observer: ZMReachabilityObserver, queue: OperationQueue?) -> Any {
        observerCount += 1
        return NSObject()
    }
    
    public func addReachabilityObserver(on queue: OperationQueue?, block: @escaping ReachabilityObserverBlock) -> Any {
        return NSObject()
    }

    public var mayBeReachable: Bool = true
    public var isMobileConnection: Bool = true
    public var oldMayBeReachable: Bool = true
    public var oldIsMobileConnection: Bool = true
    
    public func tearDown() { }
}

