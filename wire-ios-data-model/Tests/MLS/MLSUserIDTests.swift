//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
@testable import WireDataModel

final class MLSUserIDTests: XCTestCase {

    func test_ItLowercasesComponents() throws {
        // When
        let id = try XCTUnwrap(MLSUserID(userID: "FOO", domain: "BAR"))

        // Then
        XCTAssertEqual(id.rawValue, "foo@bar")
    }

    func test_ItValidatesComponents() throws {
        // When then
        XCTAssertNil(MLSUserID(userID: "", domain: "bar"))
        XCTAssertNil(MLSUserID(userID: "foo", domain: ""))
        XCTAssertNil(MLSUserID(userID: "", domain: ""))
        XCTAssertNotNil(MLSUserID(userID: "foo", domain: "bar"))
    }

    func test_ItDecodesRawValue() throws {
        // When then
        XCTAssertNil(MLSUserID(rawValue: ""))
        XCTAssertNil(MLSUserID(rawValue: "foo"))
        XCTAssertNil(MLSUserID(rawValue: "foo@"))
        XCTAssertNil(MLSUserID(rawValue: "@bar"))
        XCTAssertNil(MLSUserID(rawValue: "@"))
        XCTAssertNil(MLSUserID(rawValue: "@@@"))
        XCTAssertNil(MLSUserID(rawValue: "@foo@bar"))
        XCTAssertNil(MLSUserID(rawValue: "foo@@bar"))
        XCTAssertNil(MLSUserID(rawValue: "foo@bar@"))
        XCTAssertNotNil(MLSUserID(rawValue: "foo@bar"))
    }

}
