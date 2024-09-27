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

// MARK: - NSManagedObjectContext + GroupQueue

extension NSManagedObjectContext: GroupQueue {
    @objc public var dispatchGroup: ZMSDispatchGroup? {
        dispatchGroupContext?.groups.first
    }

    public func performGroupedBlock(_ block: @escaping () -> Void) {
        let groups = dispatchGroupContext?.enterAll() ?? []
        let timePoint = TimePoint(interval: PerformWarningTimeout)
        perform {
            timePoint.resetTime()
            block()
            self.dispatchGroupContext?.leave(groups)
            timePoint.warnIfLongerThanInterval()
        }
    }
}

extension NSManagedObjectContext {
    @objc public var pendingSaveCounter: Int {
        get { objc_getAssociatedObject(self, &AssociatedPendingSaveCountKey) as? Int ?? 0 }
        set { objc_setAssociatedObject(
            self,
            &AssociatedPendingSaveCountKey,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    @objc public var dispatchGroupContext: DispatchGroupContext? {
        get { objc_getAssociatedObject(self, &AssociatedDispatchGroupContextKey) as? DispatchGroupContext }
        set { objc_setAssociatedObject(
            self,
            &AssociatedDispatchGroupContextKey,
            newValue,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        ) }
    }

    /// List of all groups associated with this context
    @objc public var allGroups: [ZMSDispatchGroup] {
        dispatchGroupContext?.groups ?? []
    }

    @objc
    public func createDispatchGroups() {
        let groups = [
            ZMSDispatchGroup(label: "ZMSGroupQueue first"),
            // The secondary group gets -performGroupedBlock: added to it, but is not affected by
            // -notifyWhenGroupIsEmpty: -- that method needs to add extra blocks to the firstGroup, though.
            ZMSDispatchGroup(label: "ZMSGroupQueue second"),
        ]
        dispatchGroupContext = DispatchGroupContext(groups: groups)
    }

    /// Performs a block and wait for completion.
    /// @note: The block is not retained after its execution. This means that if the queue
    /// is not running (e.g. blocked by a deadlock), the block and all its captured variables
    /// will be retained, otherwise it will eventually be released.
    /// @attention: Be *very careful* not to create deadlocks.
    @objc
    public func performGroupedBlockAndWait(_ block: @escaping () -> Void) {
        let groups = dispatchGroupContext?.enterAll() ?? []
        let timePoint = TimePoint(interval: PerformWarningTimeout)
        performAndWait {
            timePoint.resetTime()
            block()
            dispatchGroupContext?.leave(groups)
            timePoint.warnIfLongerThanInterval()
        }
    }

    /// Schedules a notification block to be submitted to the receiver's
    /// queue once all blocks associated with the receiver's group have completed.
    ///
    /// If no blocks are associated with the receiver's group (i.e. the group is empty)
    /// then the notification block will be submitted immediately.
    ///
    /// The receiver's group will be empty at the time the notification block is submitted to
    /// the receiver's queue.
    ///
    /// @sa  dispatch_group_notify()
    @objc
    public func notifyWhenGroupIsEmpty(_ block: @escaping () -> Void) {
        // We need to enter & leave all but the first group to make sure that any work added by
        // this method is stil being tracked by the other groups.
        let firstGroup = dispatchGroup
        let groups = dispatchGroupContext?.enterAll(except: firstGroup) ?? []
        if let firstGroup {
            firstGroup.notify(on: .global()) {
                self.performGroupedBlock(block)
                self.dispatchGroupContext?.leave(groups)
            }
        } else {
            assertionFailure("firstGroup is nil")
            DispatchQueue.global().async {
                self.performGroupedBlock(block)
                self.dispatchGroupContext?.leave(groups)
            }
        }
    }

    /// Adds a group to the receiver. All blocks associated with the receiver's group will
    /// also be associated with this group.
    ///
    /// This is used for testing. It is not thread safe.
    @objc
    public func addGroup(_ dispatchGroup: ZMSDispatchGroup) {
        dispatchGroupContext?.add(dispatchGroup)
    }

    @objc
    public func enterAllGroups() -> [ZMSDispatchGroup] {
        dispatchGroupContext?.enterAll() ?? []
    }

    @objc
    public func leaveAllGroups(_ groups: [ZMSDispatchGroup]) {
        dispatchGroupContext?.leave(groups)
    }
}

private let PerformWarningTimeout: TimeInterval = 10
private var AssociatedDispatchGroupContextKey = 0
private var AssociatedPendingSaveCountKey = 0
