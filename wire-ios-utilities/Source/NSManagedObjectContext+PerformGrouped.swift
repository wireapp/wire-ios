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
import Foundation

public extension NSManagedObjectContext {

    static private let timeout: TimeInterval = 10

    @discardableResult
    func performGroupedAndWait<T>(_ execute: @escaping (NSManagedObjectContext) -> T) -> T {

        var result: T!
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        performAndWait {
            tp.resetTime()
            result = execute(self)
            dispatchGroupContext?.leave(groups)
            tp.warnIfLongerThanInterval()
        }

        return result
    }

    @discardableResult func performGroupedAndWait<T>(
        _ execute: @escaping (NSManagedObjectContext) throws -> T
    ) throws -> T {

        var result: T!
        var thrownError: Error?
        let groups = dispatchGroupContext?.enterAll(except: nil) ?? []
        let tp = ZMSTimePoint(interval: NSManagedObjectContext.timeout)

        performAndWait {
            do {
                tp.resetTime()
                result = try execute(self)
                dispatchGroupContext?.leave(groups)
                tp.warnIfLongerThanInterval()
            } catch {
                thrownError = error
            }
        }

        if let error = thrownError {
            dispatchGroupContext?.leave(groups)
            throw error
        } else {
            return result
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
