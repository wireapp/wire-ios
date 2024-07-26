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
    "Provided": ProvidedMacro.self
]
#endif

final class ProvidedMacrosTests: XCTestCase {

    func testItCreatesPublicProviderProtocol() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion(
            """
            @Provided
            public protocol MyUseCaseProtocol {
                func invoke()
            }
            """,
            expandedSource: """
            public protocol MyUseCaseProtocol {
                func invoke()
            }

            public protocol MyUseCaseProtocolProvider {

                func makeMyUseCaseProtocol() -> any MyUseCaseProtocol

            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testItCreatesInternalProviderProtocol() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion(
            """
            @Provided
            protocol MyUseCaseProtocol {
                func invoke()
            }
            """,
            expandedSource: """
            protocol MyUseCaseProtocol {
                func invoke()
            }

            protocol MyUseCaseProtocolProvider {

                func makeMyUseCaseProtocol() -> any MyUseCaseProtocol

            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testItDoesNotCreatePrivateProviderProtocol() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion(
            """
            @Provided
            private protocol MyUseCaseProtocol {
                func invoke()
            }
            """,
            expandedSource: """
            private protocol MyUseCaseProtocol {
                func invoke()
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Provided can not be attached to a private protocol",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testItThrowsErrorIfNotAttachedToProtocol() throws {
        #if canImport(WireMacrosMacros)
        assertMacroExpansion(
            """
            @Provided
            enum MyEnum {
                case foo
            }
            """,
            expandedSource: """
            enum MyEnum {
                case foo
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Provided can only be attached to a protocol",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}

