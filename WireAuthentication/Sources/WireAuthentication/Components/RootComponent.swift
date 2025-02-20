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
import WireReusableUIComponents
internal import WireAuthenticationUI

class RootComponent: BootstrapComponent {

    public let defaultBackendEnvironment: BackendEnvironment
    public let defaultAPIVersion: APIVersion
    public let minTLSVersion: TLSVersion
    public let accountsURL: URL
    public let passwordValidator: any PasswordValidator

    init(
        defaultBackendEnvironment: BackendEnvironment,
        defaultAPIVersion: APIVersion,
        minTLSVersion: TLSVersion,
        accountsURL: URL,
        passwordValidator: any PasswordValidator
    ) {
        self.defaultBackendEnvironment = defaultBackendEnvironment
        self.defaultAPIVersion = defaultAPIVersion
        self.minTLSVersion = minTLSVersion
        self.accountsURL = accountsURL
        self.passwordValidator = passwordValidator
    }

    @MainActor public var router: any Router {
        rootViewModel
    }

    @MainActor private var rootViewModel: RootViewModel {
        shared { RootViewModel() }
    }

    @MainActor var rootView: some View {
        RootView(
            viewModel: rootViewModel,
            builder: determineAuthMethodComponent
        )
    }

    // MARK: - Children

    var determineAuthMethodComponent: DetermineAuthMethodComponent {
        DetermineAuthMethodComponent(parent: self)
    }

}
