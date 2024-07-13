import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(WireMacrosMacros)
import WireMacrosMacros

let testMacros: [String: Macro.Type] = [
    "Provided": ProvidedMacro.self,
]
#endif

final class WireMacrosTests: XCTestCase {
    
    func testItCreatesPublicProviderProtocol() throws {
        #if canImport(ProviderMacroMacros)
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
        #if canImport(ProviderMacroMacros)
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
        #if canImport(ProviderMacroMacros)
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
        #if canImport(ProviderMacroMacros)
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
