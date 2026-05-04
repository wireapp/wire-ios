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

import NeedleFoundation
import SwiftUI
import WireAuthenticationAPI
import WireNetwork
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol VerificationEmailCodeComponentDependency: Dependency {

    var networkStack: NetworkStack { get }
    @MainActor var bridge: WireAuthenticationBridge { get }
    @MainActor var router: any Router { get }
    var registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)? { get }

}

final class VerificationEmailCodeComponent: Component<VerificationEmailCodeComponentDependency> {

    private let email: String
    private let password: String
    private let name: String
    private let trackingConsent: RegistrationAnalyticsTrackingConsent

    init(
        parent: any Scope,
        email: String,
        password: String,
        name: String,
        trackingConsent: RegistrationAnalyticsTrackingConsent
    ) {
        self.email = email
        self.password = password
        self.name = name
        self.trackingConsent = trackingConsent
        super.init(parent: parent)
    }

}

extension VerificationEmailCodeComponent: VerificationEmailCodeViewModel.Factory {

    // MARK: - Factory

    var viewModel: VerificationEmailCodeViewModel {
        VerificationEmailCodeViewModel(
            factory: self,
            router: dependency.router,
            email: email,
            password: password,
            name: name,
            onFlowCompletion: { [dependency, trackingConsent] authenticationResult in
                dependency?.registrationAnalyticsTracker?.deleteTemporaryTrackingID()
                dependency?.bridge.sendOutboundEvent(.userAuthenticated(authenticationResult, trackingConsent))
            },
            analyticsEventTracker: dependency.registrationAnalyticsTracker
        )
    }

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RegisterPersonalAccountUseCase(authenticationAPI: authenticationAPI)
    }

    func createAuthenticationResultUseCase() -> any CreateAuthenticationResultUseCaseProtocol {
        CreateAuthenticationResultUseCase(networkStack: dependency.networkStack)
    }

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RequestEmailVerificationCodeUseCase(authenticationAPI: authenticationAPI)
    }

}
