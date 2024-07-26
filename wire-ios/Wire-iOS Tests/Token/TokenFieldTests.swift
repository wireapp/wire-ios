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

import WireDesign
import WireTesting
import XCTest

@testable import Wire

final class TokenFieldTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: TokenField!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        sut = TokenField()
        sut.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 44))
        sut.backgroundColor = .black
        sut.overrideUserInterfaceStyle = .dark
        sut.textView.placeholder = "Dummy placeholder"
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    private func createTokens() {
        sut.addToken(forTitle: "Token 1", representedObject: MockUser())
        sut.addToken(forTitle: "Token 2", representedObject: MockUser())
        sut.addToken(forTitle: "Token 3", representedObject: MockUser())
        sut.addToken(forTitle: "Token 4", representedObject: MockUser())
    }

    // MARK: - Unit test

    func testThatClearFilterText() {
        // GIVEN
        createTokens()

        XCTAssertEqual(sut.textView.text.count, 8)

        // WHEN
        sut.textView.insertText("dummy")

        // WHEN
        XCTAssertEqual(sut.textView.text.count, 13)

        // WHEN
        sut.clearFilterText()

        // THEN
        // 8 tokens left, and the text is cleared
        XCTAssertEqual(sut.textView.text.count, 8)
    }

    // MARK: - Snapshot Tests

    func testThatPlaceHolderIsShownAfterAllTokensAreRemoved() {
        // GIVEN
        createTokens()

        // WHEN
        sut.removeAllTokens()

        // THEN
        XCTAssert(sut.tokens.isEmpty)

        snapshotHelper.verify(matching: sut)
    }

    func testThatTokenCanBeRemoved() {
        // GIVEN
        let token1: Token<NSObjectProtocol> = Token(title: "Token 1", representedObject: MockUser())

        // WHEN
        sut.addToken(token1)
        sut.addToken(forTitle: "Token 2", representedObject: MockUser())

        // THEN
        snapshotHelper.verify(matching: sut)

        // WHEN
        sut.removeToken(token1)

        // THEN
        XCTAssertEqual(sut.tokens.count, 1)
        XCTAssertEqual(sut.tokens.first?.title, "Token 2")

        snapshotHelper.verify(matching: sut)
    }

    func testForFilterUnwantedAttachments() {
        // GIVEN
        createTokens()

        // remove last 2 token(text and seperator) in text view
        var rangesToRemove: [NSRange] = []
        sut.textView.attributedText.enumerateAttachment { textAttachment, range, _ in
            if textAttachment is TokenContainer {
                rangesToRemove.append(range)
            }
        }

        rangesToRemove.sort(by: { rangeValue1, rangeValue2 in
            rangeValue1.location > rangeValue2.location
        })

        var numToRemove = 2
        sut.textView.textStorage.beginEditing()
        for rangeValue in rangesToRemove {
            sut.textView.textStorage.deleteCharacters(in: rangeValue)
            numToRemove -= 1
            if numToRemove <= 0 {
                break
            }
        }
        sut.textView.textStorage.endEditing()

        // WHEN
        sut.filterUnwantedAttachments()

        // THEN
        XCTAssertEqual(sut.tokens.count, 3)
    }

    func testThatColorIsChnagedAfterUpdateTokenAttachments() {
        // GIVEN
        let token1: Token<NSObjectProtocol> = Token(title: "Token 1", representedObject: MockUser())

        sut.addToken(token1)

        // WHEN
        sut.tokenTitleColor = SemanticColors.Label.textDefault
        sut.updateTokenAttachments()

        // THEN
        snapshotHelper.verify(matching: sut)
    }
}
