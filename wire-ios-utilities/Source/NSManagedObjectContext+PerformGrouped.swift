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

    static private let timeout: TimeInterval = 10

    @discardableResult @available(*, noasync)
    public func performGroupedAndWait<T>(_ execute: @escaping (NSManagedObjectContext) -> T) -> T {

        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        return performAndWait {

            tp.resetTime()
            let result = execute(self)

            dispatchGroupContext?.leave(groups)
            tp.warnIfLongerThanInterval()
            return result
        }
    }

    @discardableResult
    public func performGrouped<T>(_ execute: @escaping (NSManagedObjectContext) -> T) async -> T {

        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        return await perform {

            tp.resetTime()
            let result = execute(self)

            self.dispatchGroupContext?.leave(groups)
            tp.warnIfLongerThanInterval()
            return result
        }
    }

    @discardableResult @available(*, noasync)
    public func performGroupedAndWait<T>(
        _ execute: @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {

        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        return try performAndWait {

            tp.resetTime()
            defer {
                dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return try execute(self)
        }
    }

    @discardableResult
    public func performGrouped<T>(
        _ execute: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {

        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        return try await perform {

            tp.resetTime()
            defer {
                self.dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            }
            return try execute(self)
        }
    }
}

/**
 Wrapper around Task to make sure tests are waiting for the task to be finished using dispatchGroups attached to NSManagedObjectContext.

 We call ``NSManagedObjectContext/enterAllGroupsExceptSecondary()`` before the Task and leave the groups at the end.
 */
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
