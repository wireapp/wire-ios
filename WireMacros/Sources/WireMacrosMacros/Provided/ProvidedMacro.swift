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

public struct ProvidedMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) else {
            throw ProvidedMacroError.notAttachedToProtocol
        }

        let isPrivate = protocolDeclaration.modifiers.contains {
            $0.name.tokenKind == .keyword(.private)
        }

        guard !isPrivate else {
            throw ProvidedMacroError.privateProtocol
        }

        let isPublic = protocolDeclaration.modifiers.contains {
            $0.name.tokenKind == .keyword(.public)
        }

        let name = protocolDeclaration.name.text

        let output = """
        \(isPublic ? "public " : "")protocol \(name)Provider {

            func make\(name)() -> any \(name)

        }
        """

        return [DeclSyntax(stringLiteral: output)]
    }

}
