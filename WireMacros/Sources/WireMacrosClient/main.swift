import WireMacros

@Provided
public protocol FooUseCaseProtocol {

    func invoke()

}

struct FooUseCase: FooUseCaseProtocol {

    func invoke() {

    }

}

struct FooUseCaseProvider: FooUseCaseProtocolProvider {

    func makeFooUseCaseProtocol() -> any FooUseCaseProtocol {
        FooUseCase()
    }

}
