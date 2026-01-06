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

public class ThreadSafeDictionary<Key: Hashable, Value> {

    public init() {}

    private var dictionary = [Key: Value]()
    private let queue = DispatchQueue(label: "com.example.dictionaryQueue")

    public func set(value: Value?, for key: Key) {
        queue.async {
            self.dictionary[key] = value
        }
    }

    public func get(for key: Key) -> Value? {
        queue.sync {
            self.dictionary[key]
        }
    }

    public func remove(for key: Key) {
        queue.async {
            self.dictionary.removeValue(forKey: key)
        }
    }

    public func allItems() -> [Key: Value] {
        queue.sync {
            self.dictionary
        }
    }

    public func reset() {
        queue.async {
            self.dictionary.removeAll()
        }
    }
}
