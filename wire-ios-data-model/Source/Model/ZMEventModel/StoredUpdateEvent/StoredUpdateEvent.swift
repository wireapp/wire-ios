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

import CoreData
import Foundation

/// This is a legacy model for legacy `ZMUpdateEvent`. It is superceded by
/// `StoredUpdateEventEnvelope` and `UpdateEvent`.

@objc(StoredUpdateEvent)
public final class StoredUpdateEvent: NSManagedObject {

    static let entityName = "StoredUpdateEvent"
    static let SortIndexKey = "sortIndex"

    /// The key under which the event payload is encrypted by the public key.

    static let encryptedPayloadKey = "encryptedPayload"

    // MARK: - Properties

    @NSManaged var eventHash: Int64

    @NSManaged public var uuidString: String?

    @NSManaged var debugInformation: String?

    @NSManaged var isTransient: Bool

    @NSManaged var payload: NSDictionary?

    @NSManaged var isEncrypted: Bool

    @NSManaged var isCallEvent: Bool

    @NSManaged var source: Int16

    @NSManaged var sortIndex: Int64

}
