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

import WireLoggingSupport
import XCTest

@testable import WireLogging

final class WireLogInterpolationAnyErrorTests: XCTestCase {

    private var mockLogger: MockWireLoggerProtocol!

    override func setUp() {
        mockLogger = .init()
        mockLogger.error_MockMethod = { _ in }
    }

    override func tearDown() {
        mockLogger = nil
    }

    func testSimpleErrorIsLoggedWithObfuscation() {
        // Given
        let error = CustomError.simple

        // When
        WireLogInterpolation.isObfuscationRequired = true
        mockLogger.error("caught error: \(error)")
        WireLogInterpolation.isObfuscationRequired = false

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssertEqual(mockLogger.error_Invocations.first?.content, "caught error: CustomError")
    }

    func testSimpleErrorIsLoggedWithoutObfuscation() {
        // Given
        let error = CustomError.simple

        // When
        mockLogger.error("caught error: \(error)")

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssert(mockLogger.error_Invocations.first?.content.contains("CustomError.simple") == true)
    }

    func testSimpleErrorIsLoggedWithSkippedObfuscation() {
        // Given
        let error = CustomError.simple

        // When
        mockLogger.error("caught error: \(error, skipObfuscation: true)")

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssert(mockLogger.error_Invocations.first?.content.contains("CustomError.simple") == true)
    }

    func testWrappingErrorIsLoggedWithObfuscation() {
        // Given
        let error = CustomError.wrapping(NSFileProviderError(.directoryNotEmpty))

        // When
        WireLogInterpolation.isObfuscationRequired = true
        mockLogger.error("caught error: \(error)")
        WireLogInterpolation.isObfuscationRequired = false

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssertEqual(mockLogger.error_Invocations.first?.content, "caught error: CustomError")
    }

    func testWrappingErrorIsLoggedWithSkippedObfuscation() {
        // Given
        let error = CustomError.wrapping(NSFileProviderError(.directoryNotEmpty))

        // When
        mockLogger.error("caught error: \(error, skipObfuscation: true)")

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssert(mockLogger.error_Invocations.first?.content.contains("CustomError.wrapping(Error Domain=NSFileProviderErrorDomain Code=-1007") == true)
    }

    func testContainerErrorIsLoggedWithObfuscation() {
        // Given
        let error = CustomError.container(.init(sensibleInformation: "Lorem Ipsum"))

        // When
        WireLogInterpolation.isObfuscationRequired = true
        mockLogger.error("caught error: \(error)")
        WireLogInterpolation.isObfuscationRequired = false

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        XCTAssertEqual(mockLogger.error_Invocations.first?.content, "caught error: CustomError")
    }

    func testContainerErrorIsLoggedWithSkippedObfuscation() throws {
        // Given
        let error = CustomError.container(.init(sensibleInformation: "Lorem Ipsum"))

        // When
        mockLogger.error("caught error: \(error, skipObfuscation: true)")

        // Then
        XCTAssertEqual(mockLogger.error_Invocations.count, 1)
        let content = try XCTUnwrap(mockLogger.error_Invocations.first?.content)
        XCTAssertTrue(content.contains("CustomError.container"))
        XCTAssertTrue(content.contains("SomeType"))
        XCTAssertTrue(content.contains("Lorem Ipsum"))
    }
}

private enum CustomError: Error {
    case simple
    case wrapping(any Error)
    case container(SomeType)
}

private struct SomeType {
    var sensibleInformation: String
}
