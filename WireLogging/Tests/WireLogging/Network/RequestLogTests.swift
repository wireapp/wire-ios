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
import XCTest
@testable import WireLogging

class RequestLogTests: XCTestCase {

    func testParsingEndpoint() throws {
        let request = NSURLRequest(url: URL(string: "https://prod-nginz-https.wire.com/v2/access")!)
        guard let sut: RequestLog = .init(request) else {
            XCTFail("could not create RequestLog")
            return
        }
        XCTAssertEqual(sut.endpoint, "https://prod-nginz-https.wire.com/v2/access")
        XCTAssertEqual(sut.method, "GET")
    }

    func testParsingEndpointWithQueryParams() throws {
        let request =
            NSURLRequest(
                url: URL(
                    string: "https://prod-nginz-https.wire.com/v2/notifications?size=500&since=05b4637f-7c5a-11ed-8001-aafb9b836561&client=e00079bf207cf4e6"
                )!
            )
        guard let sut: RequestLog = .init(request) else {
            XCTFail("could not create RequestLog")
            return
        }

        XCTAssertEqual(
            sut.endpoint,
            "https://prod-nginz-https.wire.com/v2/notifications?size=500&since=05b4637f-7c5a-11ed-8001-aafb9b836561&client=e00079bf207cf4e6"
        )
    }

    func testAuthorizationHeaderValueIsRedacted() throws {
        let request = NSMutableURLRequest(url: URL(string: "https://prod-nginz-https.wire.com/push/tokens")!)
        request.addValue("Bearer wertrtetetr42343242432456789p", forHTTPHeaderField: "Authorization")
        guard let sut: RequestLog = .init(request) else {
            XCTFail("could not create RequestLog")
            return
        }
        XCTAssertEqual(sut.headers["Authorization"], "*******")
    }

}
