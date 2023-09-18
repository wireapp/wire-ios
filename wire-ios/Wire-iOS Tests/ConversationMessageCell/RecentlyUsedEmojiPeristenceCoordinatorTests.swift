//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@testable import Wire
import XCTest

final class RecentlyUsedEmojiPeristenceCoordinatorTests: XCTestCase {

    // MARK: setUp

    override func tearDown() {
        RecentlyUsedEmojiPeristenceCoordinator.store(RecentlyUsedEmojiSection(capacity: 15))
        super.tearDown()
    }

    func test_recentlyUsedEmoji_isEmpty() {
        // THEN
        XCTAssertArrayEqual(RecentlyUsedEmojiPeristenceCoordinator.loadOrCreate().emojis, [])
    }

    func test_storeAndLoadEmojis() {
        // GIVEN
        let emojis = [Emoji(value: "😂"), Emoji(value: "🆎"), Emoji(value: "🫥"), Emoji(value: "🐞")]
        let emojiSection = RecentlyUsedEmojiSection(capacity: 15, elements: emojis)

        // WHEN
        RecentlyUsedEmojiPeristenceCoordinator.store(emojiSection)

        // THEN
        XCTAssertArrayEqual(RecentlyUsedEmojiPeristenceCoordinator.loadOrCreate().emojis, emojis)

    }
}
