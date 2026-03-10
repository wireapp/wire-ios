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

import WireCommonComponents
import WireFoundation
import WireFoundationSupport
import XCTest

@testable import Wire

final class ConversationTextMessageCellTests: XCTestCase {

    var sut: ConversationTextMessageCellMock!
    var otherUser: MockUserType!
    var selfUser: MockUserType!

    override func setUp() {
        super.setUp()
        sut = ConversationTextMessageCellMock(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        otherUser = MockUserType.createUser(name: "Bruno")
        selfUser = MockUserType.createDefaultSelfUser()
    }

    override func tearDown() {
        sut = nil
        otherUser = nil
        selfUser = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testConfigureForMention() {
        // Given
        let rawText = "Hola @Bruno"
        let mentionRange = (rawText as NSString).range(of: "@Bruno")
        let mention = Mention(range: mentionRange, user: otherUser)
        // When
        applyConfig(text: rawText, mentions: [mention])
        // Then
        let attrs = getAttributes(at: mentionRange)
        XCTAssertNotNil(attrs?[.link])
        XCTAssertEqual(attrs?[.underlineStyle] as? Int, 0, "Mentions must not be underlined")
        XCTAssertEqual(attrs?[.foregroundColor] as? UIColor, UIColor.accent())
    }

    func testConfigureForLink() {
        // Given
        let rawText = "Check google.com"
        let linkRange = (rawText as NSString).range(of: "google.com")
        let linkURL = URL(string: "https://google.com")!
        let linkResult = NSTextCheckingResult.linkCheckingResult(range: linkRange, url: linkURL)
        // When
        applyConfig(text: rawText, links: [linkResult])
        // Then
        let attrs = getAttributes(at: linkRange)
        XCTAssertNotNil(attrs?[.link])
        XCTAssertEqual(attrs?[.underlineStyle] as? Int, NSUnderlineStyle.single.rawValue)
        XCTAssertEqual(attrs?[.foregroundColor] as? UIColor, UIColor.accent())
    }

    func testConfigureForAddress() {
        // Given
        let addressText = "6, Plaza de Cataluña, Barcelona, Eixample, Barcelona, 08007"
        let fullText = "Mi dirección es \(addressText)"
        let range = (fullText as NSString).range(of: addressText)

        let addressResult = NSTextCheckingResult.addressCheckingResult(
            range: range,
            components: [.city: "Barcelona", .zip: "08007"]
        )
        // When
        applyConfig(text: fullText, links: [addressResult])
        // Then
        let attrs = getAttributes(at: range)
        let urlString = (attrs?[.link] as? URL)?.absoluteString ?? ""
        XCTAssertTrue(urlString.hasPrefix("http://maps.apple.com/?q="))
        XCTAssertTrue(urlString.contains("08007"))
        XCTAssertEqual(attrs?[.underlineStyle] as? Int, NSUnderlineStyle.single.rawValue)
    }

    func testConfigureForPhoneNumber() {
        // Given
        let phoneNumber = "123456789"
        let fullText = "Llamame al \(phoneNumber)"
        let range = (fullText as NSString).range(of: phoneNumber)
        let phoneResult = NSTextCheckingResult.phoneNumberCheckingResult(range: range, phoneNumber: phoneNumber)
        // When
        applyConfig(text: fullText, links: [phoneResult])
        // Then
        let attrs = getAttributes(at: range)
        XCTAssertEqual((attrs?[.link] as? URL)?.absoluteString, "tel:\(phoneNumber)")
        XCTAssertEqual(attrs?[.underlineStyle] as? Int, NSUnderlineStyle.single.rawValue)
    }

    // MARK: - Helpers

    private func applyConfig(text: String, mentions: [Mention] = [], links: [NSTextCheckingResult] = []) {
        let config = ConversationTextMessageCell.Configuration(
            attributedText: NSAttributedString(string: text),
            isObfuscated: false,
            mentions: mentions,
            detectedLinks: links
        )
        sut.configure(with: config, animated: false)
    }

    private func getAttributes(at range: NSRange) -> [NSAttributedString.Key: Any]? {
        var effectiveRange = NSRange()
        return sut.messageTextViewExposed.attributedText?.attributes(
            at: range.location,
            effectiveRange: &effectiveRange
        )
    }
}

class ConversationTextMessageCellMock: ConversationTextMessageCell {
    var messageTextViewExposed: LinkInteractionTextView {
        super.messageTextView
    }

}
