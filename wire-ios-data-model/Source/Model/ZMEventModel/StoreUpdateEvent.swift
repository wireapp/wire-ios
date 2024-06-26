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

/// A persisted update event for later processing.
///
/// Update events may contain encrypted payloads, which typically can only
/// be decrypted once. To avoid data loss in the case of a crash or other
/// interruption, decrypted update events that aren't immediately processed
/// should be persisted as soon as possible so that they can be retrieved
/// for later processing.

@objc(StoredUpdateEvent)
public final class StoredUpdateEvent: NSManagedObject {

    public static let entityName = "StoredUpdateEvent"
    public static let SortIndexKey = "sortIndex"

    /// The event id.

    @NSManaged
    public var uuidString: String?

    /// Debug information about the event.

    @NSManaged
    public var debugInformation: String?

    /// Whether the event was delivered only through the push channel
    /// and not buffered in the event stream.

    @NSManaged
    public var isTransient: Bool

    /// The event payload.

    @available(*, deprecated, message: "use `eventData` instead")
    @NSManaged
    public var payload: NSDictionary?

    /// The encoded data of the event payload.

    @NSManaged
    public var eventData: Data?

    /// Whether the event payload is encrypted (see `Encryption at Rest`).

    @NSManaged
    public var isEncrypted: Bool

    /// Whether the event is a call event, and therefore encrypted by
    /// the secondary public EAR key.

    @NSManaged
    public var isCallEvent: Bool

    /// The source of the event.

    @NSManaged
    public var source: Int16

    /// The sort index of the event.
    ///
    /// Events should be processed in the order they are received.

    @NSManaged
    public var sortIndex: Int64

    /// Compute the highest index of all stored events.

    public static func highestIndex(in context: NSManagedObjectContext) -> Int64 {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: StoredUpdateEvent.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: StoredUpdateEvent.SortIndexKey, ascending: false)]
        fetchRequest.fetchBatchSize = 1
        let result = context.fetchOrAssert(request: fetchRequest)
        return result.first?.sortIndex ?? 0
    }

}
