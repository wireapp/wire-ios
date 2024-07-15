import Foundation
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

let uuid = #UUID("7411ca17-ba08-4905-92d2-0617a8c810ca")
print(uuid)
