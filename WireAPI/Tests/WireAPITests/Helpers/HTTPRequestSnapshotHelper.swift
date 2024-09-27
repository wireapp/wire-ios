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

import SnapshotTesting
import struct WireAPI.HTTPRequest
import XCTest

/// Provides convenience to snapshot `HTTPRequest` objects.
struct HTTPRequestSnapshotHelper {
    /// Snapshot test a given request
    /// - Parameters:
    ///   - request: httpRequest to verify
    ///   - resourceName: name of the file containing the expected request description
    ///   - file: The file invoking the test.
    ///   - function: The method invoking the test.
    ///   - line: The line invoking the test.

    @MainActor
    func verifyRequest(
        request: HTTPRequest,
        resourceName: String? = nil,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let errorMessage = verifySnapshot(
            of: request,
            as: .dump,
            named: resourceName,
            file: file,
            testName: function,
            line: line
        )

        if let errorMessage {
            XCTFail(errorMessage, file: file, line: line)
        }
    }

    /// Snapshot test a given request
    /// - Parameters:
    ///   - request: url request to verify
    ///   - resourceName: name of the file containing the expected request description
    ///   - record: if true, a new snapshot will be recorded, overwriting an existing snapshot.
    ///   - file: The file invoking the test.
    ///   - function: The method invoking the test.
    ///   - line: The line invoking the test.

    @MainActor
    func verifyRequest(
        request: URLRequest,
        resourceName: String? = nil,
        record: Bool = false,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let errorMessage = verifySnapshot(
            of: request,
            as: .curl,
            named: resourceName,
            record: record,
            file: file,
            testName: function,
            line: line
        )

        if let errorMessage {
            XCTFail(errorMessage, file: file, line: line)
        }
    }
}
