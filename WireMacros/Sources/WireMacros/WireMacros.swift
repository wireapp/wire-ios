// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that, when attached to
/// a protocol declaration, produces a companion "provider" protocol
/// that can be used inject dependencies.
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
public macro Provided() = #externalMacro(module: "WireMacrosMacros", type: "ProvidedMacro")
