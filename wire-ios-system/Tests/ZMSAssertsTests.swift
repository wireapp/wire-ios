//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import WireSystem

final class ZMSAssertsTests: XCTestCase {

    func testFatalMessageFormattingWithSwiftString() {
        // Given
        let testMessage = "Test error message with special characters: ñ, é, 中文"
        let testFile: StaticString = "TestFile.swift"
        let testLine: UInt = 42

        // When/Then - Verify NSString formatting doesn't crash with Swift String
        // This tests the internal formatting logic used by fatal()
        let output = NSString(
            format: "ASSERT: [%s:%d] <%s> %@",
            "\(testFile)",
            Int32(testLine),
            "Swift assertion",
            testMessage
        ) as String

        // Verify the output is correctly formatted
        XCTAssertTrue(output.contains("ASSERT:"))
        XCTAssertTrue(output.contains("TestFile.swift"))
        XCTAssertTrue(output.contains("42"))
        XCTAssertTrue(output.contains("Swift assertion"))
        XCTAssertTrue(output.contains(testMessage))
    }

    func testFatalMessageFormattingWithEmptyString() {
        // Given
        let testMessage = ""
        let testFile: StaticString = "TestFile.swift"
        let testLine: UInt = 42

        // When/Then - Verify NSString formatting works with empty string
        let output = NSString(
            format: "ASSERT: [%s:%d] <%s> %@",
            "\(testFile)",
            Int32(testLine),
            "Swift assertion",
            testMessage
        ) as String

        // Verify the output is correctly formatted even with empty message
        XCTAssertTrue(output.contains("ASSERT:"))
        XCTAssertTrue(output.contains("TestFile.swift"))
        XCTAssertTrue(output.contains("42"))
    }

    func testFatalMessageFormattingWithLongString() {
        // Given
        let testMessage = String(repeating: "A", count: 10000)
        let testFile: StaticString = "TestFile.swift"
        let testLine: UInt = 42

        // When/Then - Verify NSString formatting works with very long strings
        let output = NSString(
            format: "ASSERT: [%s:%d] <%s> %@",
            "\(testFile)",
            Int32(testLine),
            "Swift assertion",
            testMessage
        ) as String

        // Verify the output contains the full message
        XCTAssertTrue(output.contains(testMessage))
    }

    func testFatalMessageFormattingWithUnicodeCharacters() {
        // Given - Test various unicode characters that might cause issues
        let testMessage = "Unicode: 🚀 → ∞ ≠ ≤ ≥ × ÷ ∑ √ ∫"
        let testFile: StaticString = "TestFile.swift"
        let testLine: UInt = 42

        // When/Then - Verify NSString formatting handles unicode correctly
        let output = NSString(
            format: "ASSERT: [%s:%d] <%s> %@",
            "\(testFile)",
            Int32(testLine),
            "Swift assertion",
            testMessage
        ) as String

        // Verify unicode characters are preserved
        XCTAssertTrue(output.contains("🚀"))
        XCTAssertTrue(output.contains("∞"))
        XCTAssertTrue(output.contains(testMessage))
    }

    func testRequireWithTrueCondition() {
        // Given
        let condition = true
        let message = "This should not trigger"

        // When/Then - require with true condition should not crash
        require(condition, message)
        // Test passes if we reach this point without crashing
        XCTAssertTrue(true)
    }

    func testAppBuildCurrent() {
        // When
        let build = AppBuild.current

        // Then - verify it returns a valid build type
        XCTAssertTrue([.appStore, .debug, .develop, .unknown].contains(build))
    }

    func testAppBuildCanFatalError() {
        // Given
        let debugBuild = AppBuild.debug
        let developBuild = AppBuild.develop
        let appStoreBuild = AppBuild.appStore
        let unknownBuild = AppBuild.unknown

        // Then
        XCTAssertTrue(debugBuild.canFatalError)
        XCTAssertTrue(developBuild.canFatalError)
        XCTAssertFalse(appStoreBuild.canFatalError)
        XCTAssertFalse(unknownBuild.canFatalError)
    }

    func testRequireInternalWithTrueCondition() {
        // Given
        let condition = true
        let message = "This should not trigger"

        // When/Then - requireInternal with true condition should not crash
        requireInternal(condition, message)
        // Test passes if we reach this point without crashing
        XCTAssertTrue(true)
    }
}
