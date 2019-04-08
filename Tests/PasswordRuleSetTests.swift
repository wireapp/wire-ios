//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireUtilities

class PasswordRuleSetTests: XCTestCase {

    // MARK: - Creation

    func testThatItAddsRequiredCharactersToAllowedSet() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 10, maximumLength: 100, allowedCharacters: [.asciiPrintable], requiredCharacters: [.custom("🐼")])

        // THEN
        let panda = Unicode.Scalar(Int(0x1F43C))!
        let pandaCharset = CharacterSet(charactersIn: "🐼")

        XCTAssertEqual(ruleSet.requiredCharacterSets, [.custom("🐼"): pandaCharset])
        XCTAssertTrue(ruleSet.allowedCharacterSet.contains(panda))
        XCTAssertTrue(ruleSet.allowedCharacterSet.isSuperset(of: CharacterSet.asciiPrintableSet))
    }

    // MARK: - Validation

    func testThatItDetectsTooShortPassword() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 10, maximumLength: 100, allowedCharacters: [.unicode], requiredCharacters: [.digits])
        let shortPassword = "123456789"

        // WHEN
        let result = ruleSet.validatePassword(shortPassword)

        // THEN
        XCTAssertEqual(result, .tooShort)
    }

    func testThatItDetectsTooLongPassword() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 2, maximumLength: 8, allowedCharacters: [.unicode], requiredCharacters: [.digits])
        let longPassword = "123456789"

        // WHEN
        let result = ruleSet.validatePassword(longPassword)

        // THEN
        XCTAssertEqual(result, .tooLong)
    }

    func testThatItDetectsDisallowedCharacter() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 8, maximumLength: 120, allowedCharacters: [.asciiPrintable], requiredCharacters: [.digits])
        let passwordWithHebrew = "1Passworד"

        // WHEN
        let result = ruleSet.validatePassword(passwordWithHebrew)

        // THEN
        let dalet = Unicode.Scalar(Int(0x05D3))!
        XCTAssertEqual(result, .disallowedCharacter(dalet))
    }

    func testThatItDetectsMissingClasses() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 8, maximumLength: 120, allowedCharacters: [.asciiPrintable], requiredCharacters: [.digits, .special, .uppercase, .lowercase])
        let plainPassword = "Wire2019"

        // WHEN
        let result = ruleSet.validatePassword(plainPassword)

        // THEN
        XCTAssertEqual(result, .missingRequiredClasses([.special]))
    }

    // MARK: - Codable

    func testThatItDecodesFromJSON() throws {
        // GIVEN
        let json = """
        {
            "minimum-length": 8,
            "maximum-length": 120,
            "allowed-characters": [
                "ascii-printable",
            ],
            "required-characters": [
                "digits",
                "[🐼]"
            ]
        }
        """

        // WHEN
        let jsonDecoder = JSONDecoder()
        let ruleSet = try jsonDecoder.decode(PasswordRuleSet.self, from: Data(json.utf8))

        // THEN
        let panda = Unicode.Scalar(Int(0x1F43C))!
        let pandaCharset = CharacterSet(charactersIn: "🐼")

        XCTAssertEqual(ruleSet.minimumLength, 8)
        XCTAssertEqual(ruleSet.maximumLength, 120)
        XCTAssertEqual(ruleSet.allowedCharacters, [.asciiPrintable, .digits, .custom("🐼")])
        XCTAssertTrue(ruleSet.allowedCharacterSet.contains(panda))
        XCTAssertTrue(ruleSet.allowedCharacterSet.isSuperset(of: CharacterSet.asciiPrintableSet))
        XCTAssertEqual(ruleSet.requiredCharacterSets, [.digits: .decimalDigits, .custom("🐼"): pandaCharset])
    }

    func testThatItEncodesToAppleKeychainFormat() {
        // GIVEN
        let ruleSet = PasswordRuleSet(minimumLength: 10, maximumLength: 100, allowedCharacters: [.asciiPrintable], requiredCharacters: [.custom("🐼")])

        // WHEN
        let keychainFormat = ruleSet.encodeInKeychainFormat()

        // THEN
        XCTAssertEqual(keychainFormat, "minlength: 10; maxlength: 100; allowed: ascii-printable; allowed: [🐼]; required: [🐼];")
    }

}
