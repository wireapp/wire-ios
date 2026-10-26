//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLogging

public extension NSManagedObjectContext {

    /// Executes a fetch request and asserts in case of error
    func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T] {
        do {
            return try fetch(request)
        } catch {
            WireLogger.localStorage
                .error("CoreData: Error in fetching request : \(request),  \(error.localizedDescription)")
            if !error.isPersistentStoreGone {
                assertionFailure("Error in fetching \(error.localizedDescription)")
            }
            return []
        }
    }

    /// Counts a fetch request and asserts in case of error
    func countOrAssert(request: NSFetchRequest<some Any>) -> Int {
        do {
            return try count(for: request)
        } catch {
            WireLogger.localStorage
                .error("CoreData: Error in counting for request : \(request), \(error.localizedDescription)")
            if !error.isPersistentStoreGone {
                assertionFailure("Error in fetching \(error.localizedDescription)")
            }
            return 0
        }
    }
}

private extension Error {

    /// Whether the error means the store file can't be opened (SQLITE_CANTOPEN), which happens
    /// when the account's database was deleted during teardown (logout, account deletion, backup restore)
    /// while some work was still running on the context. This is not a programmer error.

    var isPersistentStoreGone: Bool {
        let sqliteDomain = "NSSQLiteErrorDomain"
        let sqliteCantOpen = 14

        let error = self as NSError

        // Core Data reports the SQLite result code either as a plain `NSSQLiteErrorDomain` entry in the
        // user info of the (NSCocoaErrorDomain 256) error, or as an underlying NSError.
        if let code = error.userInfo[sqliteDomain] as? Int, code == sqliteCantOpen {
            return true
        }

        if let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           underlying.domain == sqliteDomain,
           underlying.code == sqliteCantOpen {
            return true
        }

        return error.domain == sqliteDomain && error.code == sqliteCantOpen
    }
}
