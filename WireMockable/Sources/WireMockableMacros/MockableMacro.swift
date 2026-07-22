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

public import SwiftSyntaxMacros
public import SwiftSyntax

import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct MockableMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let protocolDecl = declaration.as(ProtocolDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(node: node, message: MockableDiagnostic.notAProtocol)
            )
            return []
        }

        let generator = MockGenerator(protocolDecl: protocolDecl)
        let source = generator.makeMockSource()
        return [DeclSyntax(stringLiteral: source)]
    }
}

enum MockableDiagnostic: String, DiagnosticMessage {
    case notAProtocol

    var message: String {
        switch self {
        case .notAProtocol:
            "@Mockable can only be applied to a protocol declaration."
        }
    }

    var severity: DiagnosticSeverity { .error }

    var diagnosticID: MessageID {
        MessageID(domain: "WireMockable", id: rawValue)
    }
}
