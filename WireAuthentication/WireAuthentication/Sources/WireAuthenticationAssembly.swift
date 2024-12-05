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

import Foundation
import SwiftUI
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationCore

/// The entry point for the feature module.
///
/// To load the contents of the module, create an instance of
/// the assembly, which you can then use to make required views.
@MainActor
public struct WireAuthenticationAssembly {

    public init() {}

    public func makeRootView() -> some View {
        RootView(factory: self)
    }

}

// Views are able to load other views, but the logic
// (in the form of use cases) needs to be injected from
// the assembly. The assembly injects itself as a `Factory`
// to the public views it exposes.

extension WireAuthenticationAssembly: Factory {

    public func makeDetermineAuthenticationMethodUseCase() -> any DetermineAuthenticationMethodUseCaseProtocol {
        DetermineAuthenticationMethodUseCase()
    }
    
    public func makeEmailLoginUseCase() -> any EmailLogInUseCaseProtocol {
        EmailLoginUseCase()
    }
    
    public func makePerformInitialSyncUseCase() -> any PerformInitialSyncUseCaseProtocol {
        PerformInitialSyncUseCase()
    }
    
    public func makeSubmitTwoFactorAuthenticationCodeUseCase() -> any SubmitTwoFactorAuthenticationCodeUseCaseProtocol {
        SubmitTwoFactorAuthenticationCodeUseCase()
    }

}
