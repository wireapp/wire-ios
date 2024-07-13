import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct WireMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ProvidedMacro.self,
    ]
}

public enum ProvidedMacroError: Error, CustomStringConvertible {

    case notAttachedToProtocol
    case privateProtocol

    public var description: String {
        switch self {
        case .notAttachedToProtocol:
            "@Provided can only be attached to a protocol"

        case .privateProtocol:
            "@Provided can not be attached to a private protocol"
        }
    }

}

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
