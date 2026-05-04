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

public extension StoredUpdateEventEnvelope {

    /// Insert a new object.
    ///
    /// - Parameters:
    ///   - data: JSON encoded data containing the envelope.
    ///   - sortIndex: An index specifying the order of the envelope.
    ///   - context: The context to insert into.
    ///
    /// - Returns: The newly inserted object.

    @discardableResult
    static func insertNewObject(
        data: Data,
        sortIndex: Int64,
        in context: NSManagedObjectContext
    ) -> StoredUpdateEventEnvelope {
        let object = StoredUpdateEventEnvelope(context: context)
        object.data = data
        object.sortIndex = sortIndex
        return object
    }

    /// A fetch request to get the last (highest sort index) object.

    static var lastObjectFetchRequest: NSFetchRequest<StoredUpdateEventEnvelope> {
        let request = sortedFetchRequest(asending: false)
        request.fetchLimit = 1
        return request
    }

    /// Create a fetch request sorted by the `sortIndex`.
    ///
    /// - Parameter asending: Whether the results are returned in ascending order.
    /// - Returns: A fetch request sorted by the `sortIndex`.

    static func sortedFetchRequest(asending: Bool) -> NSFetchRequest<StoredUpdateEventEnvelope> {
        let request = NSFetchRequest<StoredUpdateEventEnvelope>(entityName: entityName)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \StoredUpdateEventEnvelope.sortIndex,
                ascending: asending
            )
        ]
        return request
    }

    /// Create a fetch request to retrieve a single event envelope.
    ///
    /// - Parameter sortIndex: The sort index of the desired envelope.
    /// - Returns: A fetch request for a single event envelope.

    static func fetchRequest(sortIndex: Int64) -> NSFetchRequest<StoredUpdateEventEnvelope> {
        let request = NSFetchRequest<StoredUpdateEventEnvelope>(entityName: entityName)
        request.predicate = NSPredicate(format: "\(#keyPath(StoredUpdateEventEnvelope.sortIndex)) == \(sortIndex)")
        request.fetchLimit = 1
        return request
    }

    static func fetchRequest(sortIndices: [Int64]) -> NSFetchRequest<StoredUpdateEventEnvelope> {
        let request = NSFetchRequest<StoredUpdateEventEnvelope>(entityName: entityName)
        request.predicate = NSPredicate(
            format: "%K IN %@",
            #keyPath(StoredUpdateEventEnvelope.sortIndex),
            sortIndices
        )
        return request
    }
}
