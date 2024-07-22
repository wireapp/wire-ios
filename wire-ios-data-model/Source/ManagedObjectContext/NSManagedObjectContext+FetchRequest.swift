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

public extension NSManagedObjectContext {

    /// Executes a fetch request and asserts in case of error
    func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T] {
        do {
            let result = try fetch(request)
            return result
        } catch let error {
            WireLogger.localStorage.error("CoreData: Error in fetching request : \(request),  \(error.localizedDescription)")
            assertionFailure("Error in fetching \(error.localizedDescription)")
            return []
        }
    }

    /// Counts a fetch request and asserts in case of error
    func countOrAssert<T>(request: NSFetchRequest<T>) -> Int {
        do {
            let result = try count(for: request)
            return result
        } catch let error {
            WireLogger.localStorage.error("CoreData: Error in counting for request : \(request), \(error.localizedDescription)")
            assertionFailure("Error in fetching \(error.localizedDescription)")
            return 0
        }
    }
}
