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

import XCTest
@testable import Wire
import SnapshotTesting

final class ConversationReactionMessageTests: ZMSnapshotTestCase {

    // MARK: - Properties

    var sut: MessageReactionsCell!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        sut = MessageReactionsCell()
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 70)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItConfiguresWithSelfReaction() {
        // GIVEN
        let reaction = MessageReactionMetadata(emoji: .like, count: 1, isSelfUserReacting: true)
        let configuration = [reaction]

        sut.configure(with: configuration, animated: false)

        // THEN
        verify(view: sut)
    }

    func testThatItConfiguresWithOtherReactions() {
        // GIVEN
        let likeReaction = MessageReactionMetadata(emoji: .like, count: 4, isSelfUserReacting: false)
        let thumbsUpReaction = MessageReactionMetadata(emoji: .thumbsUp, count: 1, isSelfUserReacting: false)
        let thumbsDownReaction = MessageReactionMetadata(emoji: .thumbsDown, count: 6, isSelfUserReacting: false)
        let slightlySmilingReaction = MessageReactionMetadata(emoji: .smile, count: 8, isSelfUserReacting: false)
        let frowningFaceReaction = MessageReactionMetadata(emoji: .frown, count: 10, isSelfUserReacting: false)

        let configuration = [
            likeReaction,
            thumbsUpReaction,
            thumbsDownReaction,
            slightlySmilingReaction,
            frowningFaceReaction
        ]

        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 90)

        // WHEN
        sut.configure(with: configuration, animated: false)

        // THEN
        verify(view: sut)
    }

}
