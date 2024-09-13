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

@objc(ZMKeyValueStore)
public protocol KeyValueStore: NSObjectProtocol {
    func store(value: PersistableInMetadata?, key: String)
    func storedValue(key: String) -> Any?
}

@objc
public protocol ZMSynchonizableKeyValueStore: KeyValueStore {
    func enqueueDelayedSave()
}

extension NSManagedObjectContext: ZMSynchonizableKeyValueStore {
    public func store(value: PersistableInMetadata?, key: String) {
        setPersistentStoreMetadata(value, key: key)
    }

    public func storedValue(key: String) -> Any? {
        persistentStoreMetadata(forKey: key)
    }
}
