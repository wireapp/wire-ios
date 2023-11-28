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

class String_EmojiTests: XCTestCase {

    func testThatItDetectsAnEmoji() {
        XCTAssertTrue("🍔".containsEmoji)
    }

    func testThatItDetectsMultipleEmoji() {
        XCTAssertTrue("🍔😜🌮🎉🍕".containsEmoji)
    }

    func testThatItDetectsAnEmojiIfItIsContainedInText() {
        XCTAssertTrue("abcdefghijklmnopqrstuv🎉wxyz_1234567890-=+'\\/`~".containsEmoji)
    }

    func testThatItDoesNotDetectAnEmojiIfThereIsNone() {
        XCTAssertFalse(" abcdefghijklmnopqrstuvwxyz_1234567890-=+'\\/`~".containsEmoji)
    }

    func testThatItDoesNotDetectAnEmojiIfThereIsNone_EmptyString() {
        XCTAssertFalse("".containsEmoji)
    }

    func testThatNonLatinsNotDetectedAsContainingEmoji() {
        XCTAssertFalse("الأشخاص المفضلين".containsEmoji)
    }

    func testThatGlagoliticNotDetectedAsContainingEmoji() {
        XCTAssertFalse("ⰀⰁ".containsEmoji)
    }

    func testThatGeorgianNotDetectedAsContainingEmoji() {
        XCTAssertFalse("ქართული".containsEmoji)
        XCTAssertFalse("Ⴀჟჯჰ".containsEmoji)
    }

    func testThatNonLatinWithEmojiIsDetectedAsContainingEmoji() {
        XCTAssertTrue("الأشخاص المفضلين🙈".containsEmoji)
    }

    func testThatNonLatinsNotDetectedAsContainingEmoji_Mandarin() {
        XCTAssertFalse("普通话/普通話".containsEmoji)
    }

    func testThatNonLatinWithEmojiIsDetectedAsContainingEmoji_Mandarin() {
        XCTAssertTrue("普通话/普通話🙈".containsEmoji)
    }
}
