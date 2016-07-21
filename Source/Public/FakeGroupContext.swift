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
import ZMCSystem

public class FakeGroupContext: NSObject, ZMSGroupQueue {

    public let dispatchGroup: ZMSDispatchGroup!
    private let queue: dispatch_queue_t!
    
    public static let mainContext = FakeGroupContext(queue: dispatch_get_main_queue(), group: ZMSDispatchGroup(label: "FakeGroupContext mainContext"))
    public static let sycnContext = FakeGroupContext(queue: dispatch_queue_create("FakeGroupContext syncContext", DISPATCH_QUEUE_SERIAL), group: ZMSDispatchGroup(label: "FakeSyncContext"))
    
    public init(queue: dispatch_queue_t, group: ZMSDispatchGroup) {
        self.queue = queue
        self.dispatchGroup = group
    }
    
    public override convenience init() {
        self.init(queue: dispatch_queue_create("FakeGroupContextPrivateQueue-\(arc4random()%1000)", DISPATCH_QUEUE_SERIAL), group: ZMSDispatchGroup(label: "FakeGroupContext"))
    }
    
    public func performGroupedBlock(block: dispatch_block_t) {
        dispatchGroup.asyncOnQueue(queue, block: block);
    }

}
