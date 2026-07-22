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

import Foundation
import SwiftSyntax

struct MockGenerator {

    let protocolDecl: ProtocolDeclSyntax

    func makeMockSource() -> String {
        var body: [String] = []
        body.append("\(accessLevelPrefix)init() {}")
        body.append(contentsOf: memberSources(from: protocolDecl.memberBlock.members))

        let joined = body.joined(separator: "\n\n")
        let indented = joined
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "    " + $0 }
            .joined(separator: "\n")

        let inheritance = protocolName + (conformsToSendable ? ", @unchecked Sendable" : "")
        let attributesPrefix = forwardedAttributes.isEmpty ? "" : forwardedAttributes + "\n"

        return """
        #if DEBUG
        \(attributesPrefix)\(accessLevelPrefix)final class \(protocolName)Mock_: \(inheritance) {
        \(indented)
        }
        #endif
        """
    }

    /// Emit mock source for every property/method in `members`, descending into
    /// any `#if`/`#elseif`/`#else` blocks and re-wrapping their contents with the
    /// same conditions so the mock only exposes those members when the protocol
    /// does.
    private func memberSources(from members: MemberBlockItemListSyntax) -> [String] {
        var results: [String] = []
        for member in members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self),
               let source = makeProperty(varDecl) {
                results.append(source)
            } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
                      let source = makeMethod(funcDecl) {
                results.append(source)
            } else if let ifConfigDecl = member.decl.as(IfConfigDeclSyntax.self),
                      let source = renderIfConfig(ifConfigDecl) {
                results.append(source)
            }
        }
        return results
    }

    private func renderIfConfig(_ decl: IfConfigDeclSyntax) -> String? {
        var lines: [String] = []
        var producedAny = false
        for clause in decl.clauses {
            let keyword = clause.poundKeyword.text
            let condition = clause.condition.map { " \($0.trimmedDescription)" } ?? ""
            lines.append("\(keyword)\(condition)")
            if let nested = clause.elements?.as(MemberBlockItemListSyntax.self) {
                let inner = memberSources(from: nested)
                if !inner.isEmpty {
                    producedAny = true
                    lines.append(inner.joined(separator: "\n\n"))
                }
            }
        }
        lines.append("#endif")
        return producedAny ? lines.joined(separator: "\n") : nil
    }

    /// Attributes on the protocol that should be reapplied to the mock class,
    /// e.g. `@MainActor` or `@available(...)`. The `@Mockable` attribute itself is excluded.
    private var forwardedAttributes: String {
        protocolDecl.attributes
            .compactMap { element -> String? in
                guard case let .attribute(attr) = element else { return nil }
                if attr.attributeName.trimmedDescription == "Mockable" { return nil }
                return attr.trimmedDescription
            }
            .joined(separator: "\n")
    }

    // MARK: - Metadata

    private var protocolName: String {
        protocolDecl.name.text
    }

    /// Access level keyword followed by a trailing space, or an empty string for `internal`.
    private var accessLevelPrefix: String {
        for modifier in protocolDecl.modifiers {
            switch modifier.name.text {
            case "public", "package": return modifier.name.text + " "
            case "open": return "public "
            default: continue
            }
        }
        return ""
    }

    private var conformsToSendable: Bool {
        guard let inheritance = protocolDecl.inheritanceClause else { return false }
        return inheritance.inheritedTypes.contains { entry in
            entry.type.trimmedDescription == "Sendable"
        }
    }

    // MARK: - Properties

    private func makeProperty(_ decl: VariableDeclSyntax) -> String? {
        guard let binding = decl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
              let typeAnnotation = binding.typeAnnotation
        else { return nil }

        let type = typeAnnotation.type
        let typeString = type.trimmedDescription
        let isOptional = type.is(OptionalTypeSyntax.self)
            || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        let acl = accessLevelPrefix

        var lines: [String] = []
        lines.append("// MARK: - \(identifier)")
        lines.append("")

        if isOptional {
            lines.append("\(acl)var \(identifier): \(typeString)")
        } else {
            let underlyingName = "underlying" + identifier.firstUppercased
            let iuoType = wrapForIUO(typeString)
            lines.append("\(acl)var \(identifier): \(typeString) {")
            lines.append("    get { \(underlyingName) }")
            lines.append("    set { \(underlyingName) = newValue }")
            lines.append("}")
            lines.append("\(acl)var \(underlyingName): \(iuoType)!")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Methods

    private func makeMethod(_ decl: FunctionDeclSyntax) -> String? {
        let name = decl.name.text
        let params = Array(decl.signature.parameterClause.parameters)
        let acl = accessLevelPrefix

        let identifier = methodIdentifier(name: name, params: params)

        let effects = decl.signature.effectSpecifiers
        let isAsync = effects?.asyncSpecifier != nil
        let isThrows = effects?.throwsClause != nil
        let asyncKw = isAsync ? " async" : ""
        let throwsKw = isThrows ? " throws" : ""
        let callPrefix = (isThrows ? "try " : "") + (isAsync ? "await " : "")

        let returnTypeSyntax = decl.signature.returnClause?.type
        let returnTypeRaw = returnTypeSyntax?.trimmedDescription
        let hasReturn = if let returnTypeRaw {
            returnTypeRaw != "Void" && returnTypeRaw != "()"
        } else {
            false
        }
        let returnType = returnTypeRaw ?? ""
        let returnIsOptional = returnTypeSyntax?.is(OptionalTypeSyntax.self) == true
            || returnTypeSyntax?.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) == true

        let paramInternalNames: [String] = params.enumerated().map { index, param in
            param.synthesizedInternalName(fallbackIndex: index)
        }
        // `@escaping` is only valid in function parameter position, so we strip
        // it from the types used inside tuple storage and closure argument lists.
        let paramTypes: [String] = params.map { typeForNonParameterPosition($0.type) }

        var lines: [String] = []
        lines.append("// MARK: - \(name)")
        lines.append("")

        // Invocation tracking.
        let trackingName: String
        if params.isEmpty {
            trackingName = "\(identifier)_CallsCount"
            lines.append("\(acl)var \(trackingName): Int = 0")
        } else if params.count == 1 {
            trackingName = "\(identifier)_Invocations"
            lines.append("\(acl)var \(trackingName): [\(paramTypes[0])] = []")
        } else {
            trackingName = "\(identifier)_Invocations"
            let tuple = zip(paramInternalNames, paramTypes)
                .map { "\($0): \($1)" }
                .joined(separator: ", ")
            lines.append("\(acl)var \(trackingName): [(\(tuple))] = []")
        }

        // Mock method closure hook.
        let closureParams = paramTypes.joined(separator: ", ")
        let closureReturn = hasReturn ? returnType : "Void"
        lines
            .append(
                "\(acl)var \(identifier)_MockMethod: ((\(closureParams))\(asyncKw)\(throwsKw) -> \(closureReturn))?"
            )

        // Fallback return value. For optional / IUO return types the storage
        // uses the return type as-is (Swift defaults it to nil), otherwise we
        // wrap in an implicitly-unwrapped optional so tests must assign a value.
        if hasReturn {
            if returnIsOptional {
                lines.append("\(acl)var \(identifier)_MockValue: \(returnType)")
            } else {
                lines.append("\(acl)var \(identifier)_MockValue: \(wrapForIUO(returnType))!")
            }
        }

        lines.append("")

        // Function implementation. We reconstruct the parameter clause so that
        // any label-only parameter (e.g. `_: Int`) gets a synthesized internal
        // name that we can reference in the generated body.
        let paramClause = renderedParameterClause(params: params, internalNames: paramInternalNames)
        let returnClause = hasReturn ? " -> \(returnType)" : ""
        lines.append("\(acl)func \(name)\(paramClause)\(asyncKw)\(throwsKw)\(returnClause) {")

        if params.isEmpty {
            lines.append("    \(trackingName) += 1")
        } else if params.count == 1 {
            lines.append("    \(trackingName).append(\(paramInternalNames[0]))")
        } else {
            let tupleArg = paramInternalNames
                .map { "\($0): \($0)" }
                .joined(separator: ", ")
            lines.append("    \(trackingName).append((\(tupleArg)))")
        }

        let callArgs = paramInternalNames.joined(separator: ", ")
        if hasReturn {
            lines.append("    if let mock = \(identifier)_MockMethod {")
            lines.append("        return \(callPrefix)mock(\(callArgs))")
            lines.append("    }")
            lines.append("    return \(identifier)_MockValue")
        } else {
            lines.append("    \(callPrefix)\(identifier)_MockMethod?(\(callArgs))")
        }

        lines.append("}")

        return lines.joined(separator: "\n")
    }

    /// Rebuilds the `(…)` parameter clause of the emitted function, inserting a
    /// synthesized internal name for any label-only parameter (`_: Int` →
    /// `_ arg0: Int`) so the generated body has an identifier to reference.
    private func renderedParameterClause(
        params: [FunctionParameterSyntax],
        internalNames: [String]
    ) -> String {
        let rendered = zip(params, internalNames).map { param, internalName in
            let external = param.firstName.text
            let namePart = external == internalName ? internalName : "\(external) \(internalName)"
            let variadic = param.ellipsis != nil ? "..." : ""
            var result = "\(namePart): \(param.type.trimmedDescription)\(variadic)"
            if let defaultValue = param.defaultValue {
                result += " \(defaultValue.trimmedDescription)"
            }
            return result
        }
        return "(\(rendered.joined(separator: ", ")))"
    }

    private func methodIdentifier(name: String, params: [FunctionParameterSyntax]) -> String {
        var result = name
        for param in params {
            let label = param.firstName.text
            if label == "_" {
                if let second = param.secondName?.text {
                    result += second.firstUppercased
                }
            } else {
                result += label.firstUppercased
            }
        }
        return result
    }

    /// Wrap a type in parentheses when needed for use as an implicitly-unwrapped optional
    /// or single-element closure argument. Function types (e.g. `() -> Void`) and any/some
    /// existentials need to be parenthesised so that trailing `!`/`?` bind to the whole type.
    private func wrapForIUO(_ type: String) -> String {
        if type.range(of: "->") != nil || type.hasPrefix("any ") || type.hasPrefix("some ") {
            return "(" + type + ")"
        }
        return type
    }

    /// Returns the textual form of `type` with `@escaping` removed. The attribute is only
    /// valid on function parameters; when the same type appears in a tuple element or a
    /// closure's argument list the compiler rejects it, so we strip it there.
    private func typeForNonParameterPosition(_ type: TypeSyntax) -> String {
        guard let attributed = type.as(AttributedTypeSyntax.self) else {
            return type.trimmedDescription
        }
        let filteredAttributes = attributed.attributes.filter { element in
            guard case let .attribute(attr) = element else { return true }
            return attr.attributeName.trimmedDescription != "escaping"
        }
        if filteredAttributes.isEmpty && attributed.specifiers.isEmpty {
            return attributed.baseType.trimmedDescription
        }
        var stripped = attributed
        stripped.attributes = AttributeListSyntax(filteredAttributes)
        return stripped.trimmedDescription
    }
}

private extension FunctionParameterSyntax {
    /// The identifier used to reference the parameter inside the generated body.
    /// Uses `secondName` when present, else `firstName`, else `argN` for
    /// label-only parameters (`_:`), where `N` is `fallbackIndex`.
    func synthesizedInternalName(fallbackIndex: Int) -> String {
        if let second = secondName?.text {
            return second
        }
        let first = firstName.text
        return first == "_" ? "arg\(fallbackIndex)" : first
    }
}

private extension String {
    var firstUppercased: String {
        guard let first else { return self }
        return String(first).uppercased() + dropFirst()
    }
}
