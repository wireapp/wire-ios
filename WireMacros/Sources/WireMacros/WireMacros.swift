// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A macro that, when attached to a protocol declaration, produces a
/// companion "provider" protocol that can be used inject dependencies.
///
/// For example:
///
///     @Provided
///     protocol MyUseCase {
///         func invoke()
///     }
///
/// will expand to:
///
///     protocol MyUseCase {
///         func invoke()
///     }
///
///     protocol MyUseCaseProvider {
///         func makeMyUseCase() -> any MyUseCase
///     }
///
/// Any object that is capable of providing the use case can
/// conform to the provider protocol:
///
///     extension Factory: MyUseCaseProvider {
///         func makeMyUseCase() -> any MyUseCase {
///             MyUseCase(...)
///         }
///     }
///
/// Instead of injecting a concrete `Factory`, we can now inject
/// some provider:
///
///     class MyViewModel {
///
///         let provider: some MyUseCaseProvider
///
///         func doSomething() {
///             let useCase = provider.makeMyUseCase()
///             useCase.invoke()
///         }
///
///     }

@attached(peer, names: suffixed(Provider))
public macro Provided() = #externalMacro(
    module: "WireMacrosMacros",
    type: "ProvidedMacro"
)

/// A macro that validates UUID strings.
///
/// For example:
///
///     let validUUID = #UUID("7411ca17-ba08-4905-92d2-0617a8c810ca")
///
/// will compile and produce a non-optional `UUID`. On the otherhand:
///
///     let invalidUUID = #UUID("foo")
///
/// will throw a compile time error.

@freestanding(expression)
public macro UUID(
    _ stringLiteral: String
) -> UUID = #externalMacro(
    module: "WireMacrosMacros",
    type: "UUIDMacro"
)
