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

import Down
@testable import Wire
import XCTest

final class MarkdownTextStorageTests: XCTestCase {

    var sut: MarkdownTextStorage!

    override func setUp() {
        super.setUp()
        sut = MarkdownTextStorage()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItCorrectlyAddsMarkdownIDAttributeAfterAutocorrect() {
        // GIVEN
        let correction = "their"
        let wholeRange = NSRange(location: 0, length: correction.count)
        sut.currentMarkdown = .bold
        // WHEN: simulate inserting autocorrected text
        sut.replaceCharacters(in: NSRange(location: 0, length: 0), with: correction)
        sut.setAttributes([:], range: wholeRange)
        // THEN
        var effectiveRange = NSRange(location: NSNotFound, length: 0)
        let result = sut.attribute(.markdownID, at: 0, effectiveRange: &effectiveRange) as? Markdown
        XCTAssertEqual(.bold, result)
        XCTAssertEqual(wholeRange, effectiveRange)
    }
}
