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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available
// when cross-compiling. Cross-compiled tests may still make use of the macro itself in
// end-to-end tests.

#if canImport(WireMacrosMacros)
import WireMacrosMacros

private let testMacros: [String: Macro.Type] = [
    "UUID": UUIDMacro.self
]
#endif

final class UUIDMacrosTests: XCTestCase {

    func testItExpandsAValidUUID() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion("""
            let uuid = #UUID("7411ca17-ba08-4905-92d2-0617a8c810ca")
            """,
            expandedSource: """
            let uuid = UUID(uuidString: "7411ca17-ba08-4905-92d2-0617a8c810ca")!
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testItThrowsErrorWithInvalidUUID() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion("""
            let uuid = #UUID("foo")
            """,
            expandedSource: """
            let uuid = #UUID("foo")
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "\"foo\" is not a valid UUID.",
                    line: 1,
                    column: 12
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testItThrowsErrorIfNotPassedAStringLiteral() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion("""
            let string = "7411ca17-ba08-4905-92d2-0617a8c810ca"
            let uuid = #UUID(string)
            """,
            expandedSource: """
            let string = "7411ca17-ba08-4905-92d2-0617a8c810ca"
            let uuid = #UUID(string)
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#UUID requires a string literal argument.",
                    line: 2,
                    column: 12
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}

