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
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol NoHistoryComponentDependency: Dependency {

    var didReauthenticate: Bool { get }
    var howToChangeEmailURL: URL { get }
    var howToDeleteAccountURL: URL { get }
    @MainActor var bridge: WireAuthenticationBridge { get }

}

final class NoHistoryComponent: Component<NoHistoryComponentDependency> {

    private let authenticationResult: AuthenticationResult
    private let didDetectDomainConflict: Bool

    init(
        parent: any Scope,
        authenticationResult: AuthenticationResult,
        didDetectDomainConflict: Bool
    ) {
        self.authenticationResult = authenticationResult
        self.didDetectDomainConflict = didDetectDomainConflict
        super.init(parent: parent)
    }

}

extension NoHistoryComponent: NoHistoryFactory {

    // MARK: - Factory

    @MainActor var viewModel: NoHistoryViewModel {
        NoHistoryViewModel(
            didReauthenticate: dependency.didReauthenticate,
            didDetectDomainConflict: didDetectDomainConflict,
            howToChangeEmailURL: dependency.howToChangeEmailURL,
            howToDeleteAccountURL: dependency.howToDeleteAccountURL,
            onFlowCompletion: { [dependency, authenticationResult] in
                dependency?.bridge.sendOutboundEvent(
                    .userAuthenticated(authenticationResult, .unknown)
                )
            }
        )
    }

}
