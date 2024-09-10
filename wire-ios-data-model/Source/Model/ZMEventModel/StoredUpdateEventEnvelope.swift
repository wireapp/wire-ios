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

/// A persisted update event envelope for later processing.
///
/// Event envelopes contain one or more update events, which may or may not
/// be encrypted. Encrypted events can only be decrypted once, so to avoid
/// data loss in the case of a crash or other interruption, decrypted events
/// that aren't immediately processed should be persisted as soon as possible.
/// This ensures that they can be retrieved later for processing.

public final class StoredUpdateEventEnvelope: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "StoredUpdateEventEnvelope"

    /// The encoded data of the event envelope.

    @NSManaged
    public var data: Data

    /// The sort index of the event.
    ///
    /// Events should be processed in the order they are received.

    @NSManaged
    public var sortIndex: Int64

    /// Create a fetch request sorted by the `sortIndex`.
    ///
    /// - Parameter asending: Whether the results are returned in ascending order.
    /// - Returns: A fetch request sorted by the `sortIndex`.

    public static func sortedFetchRequest(asending: Bool) -> NSFetchRequest<StoredUpdateEventEnvelope> {
        let request = NSFetchRequest<StoredUpdateEventEnvelope>(entityName: entityName)
        request.sortDescriptors = [
            NSSortDescriptor(
                keyPath: \StoredUpdateEventEnvelope.sortIndex,
                ascending: asending
            )
        ]
        return request
    }
}
