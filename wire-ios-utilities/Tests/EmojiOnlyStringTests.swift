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
import XCTest

class EmojiOnlyStringTests: XCTestCase {
    func testThatCommonEmojisAreDetected() {
        // given
        let commonEmoji = ["©️", "ℹ️", "☘️", "⏰️", "➰️", "♥️", "🀄️", "🇨🇭", "⭔", "⭕",
                           "😜", "🙏", "🌝", "😘", "👍", "💩", "😂", "😍", "😁",
                           "❤︎", "❤️", "🈚︎", "🀄︎", // emoji variation
                           "👩", "👩🏻", "👩🏼", "👩🏽", "👩🏾", "👩🏿", // Fitzpatrick modifiers
                           "👨‍👩‍👧", "🏳️‍🌈", // Joining
                           "🧘🏿‍♀️", "🧡", "🦒", "🧦", "🏴󠁧󠁢󠁷󠁬󠁳󠁿", "🧟‍♂️" // Emoji 5.0
                           // swiftlint:disable:next todo_requires_jira_link
                           // TODO: Test for Emoji 11.0 new emoji "🥮" after iOS 12.1 is released
        ]

        // then
        for item in commonEmoji {
            XCTAssert(item.containsOnlyEmojiWithSpaces, "Failed: \(item)")
            XCTAssert(item.containsEmoji, "Failed: \(item)")
        }
    }

    func testThatSeveralEmojisAreDetected() {
        // given
        let commonEmojiGroups = ["😜🙏🌝😘", "👍💩😂😍", "😁💁🙌", "👯😻"]
        // then
        for commonEmojiGroup in commonEmojiGroups {
            XCTAssertTrue(commonEmojiGroup.containsOnlyEmojiWithSpaces)
        }
    }

    func testThatSeveralEmojisWithSpacesAreDetected() {
        // given
        let commonEmojiGroups = ["😜      🙏 🌝 😘", "    👍💩😂😍", "😁💁🙌 ", "👯 😻"]
        // then
        for commonEmojiGroup in commonEmojiGroups {
            XCTAssertTrue(commonEmojiGroup.containsOnlyEmojiWithSpaces, "Failed: \(commonEmojiGroup)")
        }
    }

    func testThatNewEmojisAreDetected() {
        // given
        let newEmoji = ["💪🏾", "🤘🏼", "👶🏼", "💅🏼"]
        // then
        for item in newEmoji {
            XCTAssertTrue(item.containsOnlyEmojiWithSpaces, "Failed: \(item)")
        }
    }

    func testThatSeveralNewEmojisAreDetected() {
        // given
        let newEmojiGroups = ["💪🏾🤘🏼", "👶🏼💅🏼🤘🏼"]
        // then
        for newEmojiGroup in newEmojiGroups {
            XCTAssertTrue(newEmojiGroup.containsOnlyEmojiWithSpaces, "Failed: \(newEmojiGroup)")
        }
    }

    func testThatSeveralNewEmojisWithSpacesAreDetected() {
        // given
        let newEmojiGroupsWithSpaces = [" 💪🏾🤘🏼", "👶🏼 💅🏼    🤘🏼 "]
        // then
        for newEmojiGroupsWithSpace in newEmojiGroupsWithSpaces {
            XCTAssertTrue(newEmojiGroupsWithSpace.containsOnlyEmojiWithSpaces, "Failed: \(newEmojiGroupsWithSpace)")
        }
    }

    func testThatASCIISymbolsAreNotDetected() {
        // given
        let langaugeStrings = ["=", "+", "$"]

        // then
        for langaugeString in langaugeStrings {
            XCTAssertFalse(langaugeString.containsOnlyEmojiWithSpaces, "\(langaugeString) has emojis")
            XCTAssertFalse(langaugeString.containsEmoji, "\(langaugeString) contains emojis")
        }
    }

    func testThatLangaugeStringIsNotDetected() {
        // given

        // Notice: "⿆" - Kangxi Radicals, start from U0x2F0x it is not a emoji, but CharacterSet.symbols contains it.
        let langaugeStrings = ["ḀẀẶỳ", "ठःअठी३", "勺卉善爨", "Ёжик", "한국어",
                               "ⰀⰁ", // Glagolitic, start from U0x2C0x, containsEmoji return true for this language
                               "はい",// Hiragana, start from U0x304x
                               "ブ",// Katakana, start from U0x304x
                               "ㄅㄆㄇ", // Bopomofo, start from U0x310x
                               "Ⴀჟჯჰ", // Georgian, updated in uncodie 11.0
                               "ქართული", // Georgian, updated in uncodie 11.0
                               " Α α, Β β, Γ γ, Δ δ, Ε ε, Ζ ζ, Η η, Θ θ, Ι ι, Κ κ, Λ λ, Μ μ, Ν ν, Ξ ξ, Ο ο, Π π, Ρ ρ, Σ σ/ς, Τ τ, Υ υ, Φ φ, Χ χ, Ψ ψ, Ω ω.", // Greek
                               "。，？！" // Chinese punctuation marks
        ]
        // then
        for langaugeString in langaugeStrings {
            XCTAssertFalse(langaugeString.containsOnlyEmojiWithSpaces, "\(langaugeString) has emojis")
            XCTAssertFalse(langaugeString.containsEmoji, "\(langaugeString) contains emojis")
        }
    }

    func testThatRTLStringIsNotDetected() {
        // given
        let rtlStrings = ["  באמת!‏"]
        // then
        for rtlString in rtlStrings {
            XCTAssertFalse(rtlString.containsOnlyEmojiWithSpaces)
        }
    }

    func testThatLanguageStringWithEmojiNotDetected() {
        // given
        let languageEmojiStrings = ["😜ḀẀẶỳ", "👯ठःअठी३", "👯勺卉善爨", "👯Ёжик"]
        // then
        for languageEmojiString in languageEmojiStrings {
            XCTAssertFalse(languageEmojiString.containsOnlyEmojiWithSpaces, "Failed: \(languageEmojiString)")
            XCTAssert(languageEmojiString.containsEmoji)
        }
    }

    func testThatEmptyStringIsNotDetected() {
        XCTAssertFalse("".containsOnlyEmojiWithSpaces)
    }
}
