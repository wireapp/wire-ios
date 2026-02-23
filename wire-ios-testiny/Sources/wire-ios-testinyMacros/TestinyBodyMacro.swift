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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

public struct TestinyBodyMacro: BodyMacro {

    public static func expansion(
        of attribute: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {

        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else { return [] }

        let keys = parseKeys(from: attribute)
        guard !keys.isEmpty else {
            return (try funcDecl.body?.statements.map { try CodeBlockItemSyntax(validating: $0) }) ?? []
        }

        let arrayLiteral = keys.map { "\"\($0)\"" }.joined(separator: ", ")

        let injected: CodeBlockItemSyntax = """
        TestinyRuntime.record([\(raw: arrayLiteral)])
        """

        let original = (try funcDecl.body?.statements.map { try CodeBlockItemSyntax(validating: $0) }) ?? []
        return [injected] + original
    }

    private static func parseKeys(from attribute: AttributeSyntax) -> [String] {
        guard let args = attribute.arguments?.as(LabeledExprListSyntax.self) else { return [] }
        var result: [String] = []

        for arg in args {
            guard let literal = arg.expression.as(StringLiteralExprSyntax.self) else { continue }
            var value = ""
            for segment in literal.segments {
                if let s = segment.as(StringSegmentSyntax.self) { value += s.content.text }
            }
            if !value.isEmpty { result.append(value) }
        }
        return result
    }
}

@main
struct WireIOSTestinyPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [TestinyBodyMacro.self]
}
