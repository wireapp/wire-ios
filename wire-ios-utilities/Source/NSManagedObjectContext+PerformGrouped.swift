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

extension NSManagedObjectContext {
    private static let timeout: TimeInterval = 10

    @discardableResult @available(*, noasync)
    public func performGroupedAndWait<T>(_ block: () -> T) -> T {
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        return performAndWait {
            let tp = TimePoint(interval: NSManagedObjectContext.timeout)
            defer {
                dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return block()
        }
    }

    @discardableResult
    public func performGrouped<T>(_ block: @escaping () -> T) async -> T {
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        return await perform {
            let tp = TimePoint(interval: NSManagedObjectContext.timeout)
            defer {
                self.dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return block()
        }
    }

    @discardableResult @available(*, noasync)
    public func performGroupedAndWait<T>(_ block: () throws -> T) throws -> T {
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        return try performAndWait {
            let tp = TimePoint(interval: NSManagedObjectContext.timeout)
            defer {
                dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return try block()
        }
    }

    @discardableResult
    public func performGrouped<T>(
        _ execute: @escaping () throws -> T
    ) async throws -> T {
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        return try await perform {
            let tp = TimePoint(interval: NSManagedObjectContext.timeout)
            defer {
                self.dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return try execute()
        }
    }
}

// MARK: - WaitingGroupTask

/// Wrapper around Task to make sure tests are waiting for the task to be finished using dispatchGroups attached to
/// NSManagedObjectContext.
///
/// We call `NSManagedObjectContext/enterAllGroupsExceptSecondary()` before the Task and leave the groups at the end.
public struct WaitingGroupTask {
    let context: NSManagedObjectContext

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    public func callAsFunction(_ block: @escaping () async -> Void) {
        let groups = context.enterAllGroupsExceptSecondary()
        Task {
            await block()
            context.leaveAllGroups(groups)
        }
    }
}
