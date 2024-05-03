//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import CoreData
import WireSystem

extension NSManagedObjectContext: GroupQueue {

    @objc
    public var dispatchGroup: ZMSDispatchGroup {
        dispatchGroupContext.groups[0]
    }

    /// Performs a block and wait for completion.
    /// @note: The block is not retained after its execution. This means that if the queue
    /// is not running (e.g. blocked by a deadlock), the block and all its captured variables
    /// will be retained, otherwise it will eventually be released.
    /// @attention: Be *very careful* not to create deadlocks.
    @objc
    public func performGroupedBlock(_ block: @escaping () -> Void) {
        let groups = dispatchGroupContext.enterAll()
        let timePoint = TimePoint(interval: PerformWarningTimeout)
        performAndWait {
            timePoint.resetTime()
            block()
            dispatchGroupContext.leave(groups)
            timePoint.warnIfLongerThanInterval()
        }
    }
}

extension NSManagedObjectContext {

    private(set) var pendingSaveCounter: Int {
        get { objc_getAssociatedObject(self, &AssociatedPendingSaveCountKey) as? Int ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedPendingSaveCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc
    var dispatchGroupContext: DispatchGroupContext {
        get { objc_getAssociatedObject(self, &AssociatedDispatchGroupContextKey) as! DispatchGroupContext }
        set { objc_setAssociatedObject(self, &AssociatedDispatchGroupContextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @objc
    func createDispatchGroups() {
        let groups = [
            ZMSDispatchGroup(label: "ZMSGroupQueue first"),
            // The secondary group gets -performGroupedBlock: added to it, but is not affected by -notifyWhenGroupIsEmpty: -- that method needs to add extra blocks to the firstGroup, though.
            ZMSDispatchGroup(label: "ZMSGroupQueue second")
        ]
        dispatchGroupContext = DispatchGroupContext(groups: groups)
    }
}

private let PerformWarningTimeout: TimeInterval = 10
private var AssociatedDispatchGroupContextKey = 0
private var AssociatedPendingSaveCountKey = 0
