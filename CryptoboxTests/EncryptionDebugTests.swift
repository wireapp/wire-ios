//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import Cryptobox

class EncryptionDebugTests : XCTestCase {
    
    func testThatItSplitsString() {
        XCTAssertEqual("12345678".split(bySize: 3), ["123", "456", "78"])
        XCTAssertEqual("12".split(bySize: 3), ["12"])
        XCTAssertEqual("123456".split(bySize: 3), ["123", "456"])
    }
    
    func testThatItDumpBase64() {
        
        // GIVEN
        var seed = "12345678"
        (0..<5).forEach { _ in
            seed += seed
        }
        let data = seed.data(using: .utf8)!
        
        // WHEN
        let dump = data.base64Dump
        
        // THEN
        let joined = dump.components(separatedBy: "\n").joined(separator: "")
        XCTAssertEqual(joined, "--START--\(data.base64EncodedString())--END--")
    }
    
    func testThatItDumpBase64_long() {
        
        // GIVEN
        var seed = "12345678"
        (0..<15).forEach { _ in
            seed += seed
        }
        let data = seed.data(using: .utf8)!
        
        // WHEN
        let dump = data.base64Dump
        
        // THEN
        let joined = dump.components(separatedBy: "\n").joined(separator: "")
        XCTAssertEqual(joined, "--START--\(data.base64EncodedString())--END--")
    }
}
