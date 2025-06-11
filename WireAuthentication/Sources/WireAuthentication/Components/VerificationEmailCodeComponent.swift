//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol VerificationEmailCodeComponentDependency: Dependency {

    // @MainActor var router: any Router { get } // do we need?
    var networkStack: NetworkStack { get }
    @MainActor var bridge: WireAuthenticationBridge { get }

}

final class VerificationEmailCodeComponent: Component<VerificationEmailCodeComponentDependency> {

    private let email: String
    private let password: String
    private let name: String
//    public let networkStack: NetworkStack maybe we need

    init(
        parent: any Scope,
        email: String,
        password: String,
        name: String
    ) {
        self.email = email
        self.password = password
        self.name = name
        super.init(parent: parent)
    }

}

extension VerificationEmailCodeComponent: VerificationEmailCodeViewModel.Factory {

    // MARK: - Factory

    var viewModel: VerificationEmailCodeViewModel {
        VerificationEmailCodeViewModel(
            factory: self,
            email: email,
            password: password,
            name: name,
            onFlowCompletion: { [dependency] authenticationResult in
                dependency?.bridge.sendOutboundEvent(.userAuthenticated(authenticationResult))
            }
        )
    }

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RegisterPersonalAccountUseCase(authenticationAPI: authenticationAPI)
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        CreateAuthenticationResultUseCase(networkStack: dependency.networkStack)
    }

}
