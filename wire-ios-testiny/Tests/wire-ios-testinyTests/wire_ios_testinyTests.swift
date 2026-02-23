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

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(wire_ios_testinyMacros)
    import wire_ios_testinyMacros

    private let testMacros: [String: Macro.Type] = [
        "testiny": TestinyBodyMacro.self
    ]
#endif

final class wire_ios_testinyTests: XCTestCase {

    func testTestinyMacro_singleKey() throws {
        #if canImport(wire_ios_testinyMacros)
            assertMacroExpansion(
                """
                @testiny("TC-1111")
                func testLogin() throws {
                    // test body
                }
                """,
                expandedSource: """
                func testLogin() throws {
                    TestinyRuntime.record(["TC-1111"])
                    // test body
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testTestinyMacro_multipleKeys() throws {
        #if canImport(wire_ios_testinyMacros)
            assertMacroExpansion(
                """
                @testiny("TC-1111", "TC-2222", "TC-3333")
                func testFlow() throws {
                    // test body
                }
                """,
                expandedSource: """
                func testFlow() throws {
                    TestinyRuntime.record(["TC-1111", "TC-2222", "TC-3333"])
                    // test body
                }
                """,
                macros: testMacros
            )
        #else
            throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
