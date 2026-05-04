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

import Combine
import Foundation
import NeedleFoundation
import SwiftUI
import WireAuthenticationAPI
import WireFoundation
import WireMultiBackendUI
import WireNetwork
import WireReusableUIComponents
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

public typealias WireAuthenticationBridge = WireAuthenticationAPI.WireAuthenticationBridge

public struct WireAuthenticationAssembly {

    public init() {
        registerProviderFactories()
    }

    @MainActor
    public func assemble(
        authenticationType: AuthenticationType,
        environment: BackendEnvironment2,
        minTLSVersion: TLSVersion,
        preferredAPIVersion: APIVersion?,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        appStoreURL: URL,
        accountsPublisher: CurrentValuePublisher<[AccountUIModel]>,
        registrationAnalyticsTracker: (any RegistrationAnalyticsTrackerProtocol)?
    ) -> (view: some View, bridge: WireAuthenticationBridge) {
        let rootComponent = RootComponent(
            authenticationType: authenticationType,
            environment: environment,
            preferredAPIVersion: preferredAPIVersion,
            minTLSVersion: minTLSVersion,
            howToChangeEmailURL: howToChangeEmailURL,
            howToDeleteAccountURL: howToDeleteAccountURL,
            privacyPolicyURL: privacyPolicyURL,
            termsOfUseURL: termsOfUseURL,
            passwordValidator: passwordValidator,
            ssoCallbackURLScheme: ssoCallbackURLScheme,
            appStoreURL: appStoreURL,
            accountsPublisher: accountsPublisher,
            registrationAnalyticsTracker: registrationAnalyticsTracker
        )

        return (view: RootView(factory: rootComponent), bridge: rootComponent.bridge)
    }

}
