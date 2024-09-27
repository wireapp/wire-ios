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

import Foundation
import WireDataModel

private let lastUpdateEventIDKey = "LastUpdateEventID"

// MARK: - ZMLastNotificationIDStore

@objc
public protocol ZMLastNotificationIDStore {
    var zm_lastNotificationID: UUID? { get set }
    var zm_hasLastNotificationID: Bool { get }
}

// MARK: - NSManagedObjectContext + ZMLastNotificationIDStore

extension NSManagedObjectContext: ZMLastNotificationIDStore {
    public var zm_lastNotificationID: UUID? {
        get {
            guard let uuidString = persistentStoreMetadata(forKey: lastUpdateEventIDKey) as? String,
                  let uuid = UUID(uuidString: uuidString)
            else {
                return nil
            }
            return uuid
        }
        set(newValue) {
            if let value = newValue, let previousValue = zm_lastNotificationID,
               value.isType1UUID, previousValue.isType1UUID,
               previousValue.compare(withType1: value) != .orderedAscending {
                return
            }
            Logging.eventProcessing.debug("Setting zm_lastNotificationID = \(newValue?.transportString() ?? "nil")")
            setPersistentStoreMetadata(newValue?.uuidString, key: lastUpdateEventIDKey)
        }
    }

    public var zm_hasLastNotificationID: Bool {
        zm_lastNotificationID != nil
    }
}
