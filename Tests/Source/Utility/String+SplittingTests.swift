// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import XCTest
@testable import zmessaging

extension SequenceType where Generator.Element == String {
    func containsElementLongerThan(max: Int) -> Bool {
        return map { $0.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) }.filter { $0 > max }.count > 0
    }
}

class String_SplittingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSplitWordFunctionShouldSplitAfterMaxLenghts() {
        // given
        let string = "abcdf😃b"
        let maxLength = 4

        // when
        let splitted = string.splitWord(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["abcd", "f", "😃", "b"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testSplitWordShouldReturnEmptyArrayInCaseOfEmptyString() {
        // given
        let string = ""
        let maxLength = 4

        // when
        let splitted = string.splitWord(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, 0)
        XCTAssertEqual(splitted, [])
    }

    func testSplitInSubstringsReturnsEmptyArrayInCaseOfStringUnderMaxLength() {
        // given
        let string = "Cronut kale chips blue bottle shabby chic pickled squid, poutine banjo next level. "
        let maxLength = 1000

        // when
        let splitted = string.splitWord(maxLength)

        // then
        let expected = [string]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitArabicWords() {
        // given
        let string = "الجنرال"
        let maxLength = 4

        // when
        let splitted = string.splitWord(maxLength)

        // then
        let expected = ["ال" ,"جن","را","ل"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitSingleWord() {
        // given
        let string = "Hello"
        let maxLength = 3

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["Hel", "lo"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldntSplitLinks() {
        // given
        let string = "This awesome link: www.google.com"
        let maxLength = 15

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["This awesome ", "link: ", "www.google.com"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitMultillineAndTabbedSentences() {
        // given
        let string = "Hello\nWorld! How are you doing\t\r today?"
        let maxLength = 7

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["Hello\n", "World! ", "How ", "are ", "you ", "doing\t\r", " ", "today?"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSpliChineseSentence() {
        // given
        let string = "你是从哪里来的？"
        let maxLength = 10

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["你是从", "哪里来", "的？"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitPunctuationInsideCharacters() {
        // given
        let string = "Hello|/tWorld"
        let maxLength = 5

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["Hello", "|/" , "tWorl", "d"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitStringInArabic() {
        // given
        let string = "الجنرال عر"
        let maxLength = 5

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        let expected = ["ال", "جن", "را", "ل ", "عر"]
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitIfMaxLengthExceeded() {
        // given
        let string = "Pr oin"
        let maxLength = 2

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["Pr", " ", "oi", "n"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldSplitAfterWord() {
        // given
        let string = "Proin nisi"
        let maxLength = 7

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["Proin ", "nisi"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItSplitsAfterMaxLengthSimpleCharacters() {
        // given
        let string = "O Pr sdflkj s falkjas"
        let maxLength = 3

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["O ","Pr ", "sdf", "lkj", " ", "s ", "fal", "kja", "s"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItSplitsAfterMaxLengthWithCombinedCharacters() {
        // given
        let string = "¿Cómo se llama tu madre?"
        let maxLength = 3

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["¿C", "óm", "o ", "se ", "lla", "ma ", "tu ", "mad", "re?"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldPreserveWordsConsistingOnlyOfPunctuation() {
        // given
        let string = "....¿Cómo!! Yo e ... $$$"
        let maxLength = 4

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["....", "¿C", "ómo", "!! ", "Yo ", "e ..", ". $$", "$"]
        let largerThanLength = splitted.map { $0.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) }.filter { $0 > maxLength }
        XCTAssertEqual(largerThanLength.count, 0)
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testItShouldIncludeLeadingPunctuation() {
        // given
        let string = "?Yo e ..."
        let maxLength = 4

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["?Yo ", "e ..", "."]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }

    func testSplitStringShouldSplitAfterMaxLenghtsEmojis() {
        // given
        let string = "😀😔😌😋😲 Hallo\u{E9}\u{20DD}"
        let maxLength = 5

        // when
        let splitted = string.splitInSubstrings(maxLength)

        // then
        let expected = ["😀", "😔", "😌", "😋", "😲 ","Hallo", "\u{E9}\u{20DD}"]
        XCTAssertFalse(splitted.containsElementLongerThan(maxLength))
        XCTAssertEqual(splitted.count, expected.count)
        XCTAssertEqual(splitted, expected)
    }
}
