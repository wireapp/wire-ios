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

final class RecentlyUsedEmojiSection: EmojiDataSource.Section {
    // MARK: Lifecycle

    init(
        capacity: Int,
        items: [Emoji] = []
    ) {
        self.capacity = capacity
        self.backing = NSMutableOrderedSet(array: items)
        super.init(id: .recent, items: items)
        updateContent()
    }

    // MARK: Internal

    // MARK: - Methods

    @discardableResult
    func register(_ emoji: Emoji) -> Bool {
        switch backing.index(of: emoji) {
        case 0:
            // No update neccessary if the first element is already the new one
            return false

        case NSNotFound:
            backing.insert(emoji, at: 0)

        case let idx:
            backing.moveObjects(at: IndexSet(integer: idx), to: 0)
        }

        updateContent()
        return true
    }

    // MARK: Private

    // MARK: - Properties

    private let capacity: Int
    private let backing: NSMutableOrderedSet

    private func updateContent() {
        defer { items = backing.array as! [Emoji] }
        guard backing.count > capacity else { return }
        backing.removeObjects(at: IndexSet(integersIn: capacity ..< backing.count))
    }
}
