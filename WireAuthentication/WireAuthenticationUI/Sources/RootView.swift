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

import SwiftUI
import WireAuthenticationAPI

// Ideally we are using Swift packages (instead of Xcode projects),
// which would allow us to use the `package` access modifier instead
// of `public`. This means that `RootView` would be accesible to the
// assembly but not outside of the assembly.

public struct RootView: View {

    let factory: any Factory

    @StateObject
    private var router = Router()

    public init(factory: any Factory) {
        self.factory = factory
    }

    public var body: some View {
        NavigationStack(path: $router.path) {
            landing.navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .landing:
                    landing

                case .login:
                    login(isRegistrationAllowed: false)

                case .loginOrRegister:
                    login(isRegistrationAllowed: true)

                case .twoFactorAuthentication:
                    twoFactorAuthentication
                }
            }
        }
    }

    private var landing: some View {
        LandingView(
            viewModel: LandingViewModel(
                router: router,
                determineAuthenticationMethod: factory.makeDetermineAuthenticationMethodUseCase()
            )
        )
    }

    private func login(isRegistrationAllowed: Bool) -> some View {
        LoginView(
            viewModel: LoginViewModel(
                router: router,
                emailLogIn: factory.makeEmailLoginUseCase(),
                isRegistrationAllowed: isRegistrationAllowed
            )
        )
    }

    private var twoFactorAuthentication: some View {
        TwoFactorAuthenticationView(
            viewModel: TwoFactorAuthenticationViewModel(
                router: router,
                submitCode: factory.makeSubmitTwoFactorAuthenticationCodeUseCase()
            )
        )
    }
}

#Preview {
    RootView(factory: FactoryMock())
}

struct FactoryMock: Factory {

    func makeDetermineAuthenticationMethodUseCase() -> any DetermineAuthenticationMethodUseCaseProtocol {
        DetermineAuthenticationMethodUseCaseMock()
    }
    
    func makeEmailLoginUseCase() -> any EmailLogInUseCaseProtocol {
        EmailLogInUseCaseMock()
    }
    
    func makePerformInitialSyncUseCase() -> any PerformInitialSyncUseCaseProtocol {
        PerformInitialSyncUseCaseMock()
    }
    
    func makeSubmitTwoFactorAuthenticationCodeUseCase() -> any SubmitTwoFactorAuthenticationCodeUseCaseProtocol {
        SubmitTwoFactorAuthenticationCodeUseCaseMock()
    }

}
