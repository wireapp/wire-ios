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

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import WireMockableMacros

final class MockableMacroTests: XCTestCase {

    private let macros: [String: any Macro.Type] = [
        "Mockable": MockableMacro.self
    ]

    func testEmptyPublicProtocol() {
        assertMacroExpansion(
            """
            @Mockable
            public protocol Foo {}
            """,
            expandedSource: """
            public protocol Foo {}

            #if DEBUG
            public final class FooMock: Foo {
                public init() {
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testMethodWithoutParametersOrReturn() {
        assertMacroExpansion(
            """
            @Mockable
            protocol Foo {
                func ping()
            }
            """,
            expandedSource: """
            protocol Foo {
                func ping()
            }

            #if DEBUG
            final class FooMock: Foo {
                init() {
                }

                // MARK: - ping

                var ping_CallsCount: Int = 0
                var ping_MockMethod: (() -> Void)?

                func ping() {
                    ping_CallsCount += 1
                    ping_MockMethod?()
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testMethodWithParametersAndReturn() {
        assertMacroExpansion(
            """
            @Mockable
            public protocol UserService {
                func loadUser(id: UUID) async throws -> String
            }
            """,
            expandedSource: """
            public protocol UserService {
                func loadUser(id: UUID) async throws -> String
            }

            #if DEBUG
            public final class UserServiceMock: UserService {
                public init() {
                }

                // MARK: - loadUser

                public var loadUserId_Invocations: [UUID] = []
                public var loadUserId_MockMethod: ((UUID) async throws -> String)?
                public var loadUserId_MockValue: String!

                public func loadUser(id: UUID) async throws -> String {
                    loadUserId_Invocations.append(id)
                    if let mock = loadUserId_MockMethod {
                        return try await mock(id)
                    }
                    return loadUserId_MockValue
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testMethodWithMultipleParameters() {
        assertMacroExpansion(
            """
            @Mockable
            protocol Foo {
                func doThing(id: Int, name: String) -> Bool
            }
            """,
            expandedSource: """
            protocol Foo {
                func doThing(id: Int, name: String) -> Bool
            }

            #if DEBUG
            final class FooMock: Foo {
                init() {
                }

                // MARK: - doThing

                var doThingIdName_Invocations: [(id: Int, name: String)] = []
                var doThingIdName_MockMethod: ((Int, String) -> Bool)?
                var doThingIdName_MockValue: Bool!

                func doThing(id: Int, name: String) -> Bool {
                    doThingIdName_Invocations.append((id: id, name: name))
                    if let mock = doThingIdName_MockMethod {
                        return mock(id, name)
                    }
                    return doThingIdName_MockValue
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testReadOnlyProperty() {
        assertMacroExpansion(
            """
            @Mockable
            protocol Foo {
                var name: String { get }
            }
            """,
            expandedSource: """
            protocol Foo {
                var name: String { get }
            }

            #if DEBUG
            final class FooMock: Foo {
                init() {
                }

                // MARK: - name

                var name: String {
                    get {
                        underlyingName
                    }
                    set {
                        underlyingName = newValue
                    }
                }
                var underlyingName: String!
            }
            #endif
            """,
            macros: macros
        )
    }

    func testOptionalProperty() {
        assertMacroExpansion(
            """
            @Mockable
            protocol Foo {
                var nickname: String? { get set }
            }
            """,
            expandedSource: """
            protocol Foo {
                var nickname: String? { get set }
            }

            #if DEBUG
            final class FooMock: Foo {
                init() {
                }

                // MARK: - nickname

                var nickname: String?
            }
            #endif
            """,
            macros: macros
        )
    }

    func testSendableInheritanceAddsUncheckedSendable() {
        assertMacroExpansion(
            """
            @Mockable
            public protocol Foo: Sendable {}
            """,
            expandedSource: """
            public protocol Foo: Sendable {}

            #if DEBUG
            public final class FooMock: Foo, @unchecked Sendable {
                public init() {
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testLabelOnlyParameterGetsSynthesizedInternalName() {
        assertMacroExpansion(
            """
            @Mockable
            protocol Foo {
                func doThing(_: Int, name: String)
            }
            """,
            expandedSource: """
            protocol Foo {
                func doThing(_: Int, name: String)
            }

            #if DEBUG
            final class FooMock: Foo {
                init() {
                }

                // MARK: - doThing

                var doThingName_Invocations: [(arg0: Int, name: String)] = []
                var doThingName_MockMethod: ((Int, String) -> Void)?

                func doThing(_ arg0: Int, name: String) {
                    doThingName_Invocations.append((arg0: arg0, name: name))
                    doThingName_MockMethod?(arg0, name)
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testForwardsAttributesToMockClass() {
        assertMacroExpansion(
            """
            @Mockable
            @MainActor
            public protocol Foo {}
            """,
            expandedSource: """
            @MainActor
            public protocol Foo {}

            #if DEBUG
            @MainActor
            public final class FooMock: Foo {
                public init() {
                }
            }
            #endif
            """,
            macros: macros
        )
    }

    func testNonProtocolEmitsDiagnostic() {
        assertMacroExpansion(
            """
            @Mockable
            struct Foo {}
            """,
            expandedSource: """
            struct Foo {}
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mockable can only be applied to a protocol declaration.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }
}
