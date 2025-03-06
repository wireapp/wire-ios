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

import Foundation
import NeedleFoundation
import SwiftUI
import WireAPI
import WireAuthenticationAPI
import WireReusableUIComponents
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

public struct WireAuthenticationAssembly {

    public init() {
        registerProviderFactories()
    }

    @MainActor
    public func assemble(
        defaultBackendEnvironment: BackendEnvironment,
        minTLSVersion: TLSVersion,
        defaultAPIVersion: APIVersion,
        preferredAPIVersion: APIVersion?,
        accountsURL: URL,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        passwordValidator: any PasswordValidator,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void,
        onRegisterAccount: @escaping () -> Void
    ) -> (view: some View, bridge: WireAuthenticationBridge) {
        let rootComponent = RootComponent(
            defaultBackendEnvironment: defaultBackendEnvironment,
            defaultAPIVersion: defaultAPIVersion,
            preferredAPIVersion: preferredAPIVersion,
            minTLSVersion: minTLSVersion,
            accountsURL: accountsURL,
            howToChangeEmailURL: howToChangeEmailURL,
            howToDeleteAccountURL: howToDeleteAccountURL,
            passwordValidator: passwordValidator,
            ssoCallbackURLScheme: ssoCallbackURLScheme,
            userDefaults: userDefaults,
            onRegisterAccount: onRegisterAccount,
            onFlowCompletion: onFlowCompletion
        )

        return (view: rootComponent.view, bridge: rootComponent.bridge)
    }

}
