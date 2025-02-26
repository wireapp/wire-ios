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
        accountsURL: URL,
        passwordValidator: any PasswordValidator,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void,
        onRegisterAccount: @escaping () -> Void
    ) -> some View {
        let bridge = WireAuthenticationBridge(
            onFlowCompletion: onFlowCompletion,
            onRegisterAccount: onRegisterAccount
        )
        let rootComponent = RootComponent(
            bridge: bridge,
            defaultBackendEnvironment: defaultBackendEnvironment,
            defaultAPIVersion: defaultAPIVersion,
            minTLSVersion: minTLSVersion,
            accountsURL: accountsURL, // this is temp
            passwordValidator: passwordValidator
        )
        return rootComponent.view
    }

}
