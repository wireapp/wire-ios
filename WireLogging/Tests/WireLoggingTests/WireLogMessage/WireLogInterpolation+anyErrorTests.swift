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

import Foundation
import Testing
import WireLoggingSupport

@testable import WireLogging

struct WireLogInterpolationAnyErrorTests {

    @Test
    private func `logging URLError logs type name, domain and code`() {

        // Given
        let error = URLError(.notConnectedToInternet)

        // When
        let logMessage: WireLogMessage = "error: \(error)"

        // Then
        #expect(logMessage.content == "error: URLError(domain: NSURLErrorDomain code: -1009)")

    }

    @Test(arguments: [CustomError.simple, .wrapping(URLError(.notConnectedToInternet)), .container("secret")])
    private func `logging a custom error logs only its name`(error: CustomError) {
        // Given
        let error = CustomError.simple

        // When
        let logMessage: WireLogMessage = "error: \(error)"

        // Then
        #expect(logMessage.content.contains("CustomError"))
        #expect(!logMessage.content.contains("secret"))
        #expect(!logMessage.content.contains("URLError"))
    }

}

private enum CustomError: Error {

    case simple
    case wrapping(any Error)
    case container(SomeType)

    struct SomeType: ExpressibleByStringLiteral {
        var sensibleInformation: String
        init(stringLiteral value: StringLiteralType) {
            sensibleInformation = value
        }
    }

}
