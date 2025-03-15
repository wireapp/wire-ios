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
import WireAuthenticationAPI
internal import WireAuthenticationUI
internal import WireAuthenticationLogic
import WireReusableUIComponents

protocol NoHistoryComponentDependency: Dependency {

    // FIXME: Adjust as necessary
//    var howToChangeEmailURL: URL { get }
//    var howToDeleteAccountURL: URL { get }
//    @MainActor var bridge: WireAuthenticationBridge { get }

}

class NoHistoryComponent: Component<NoHistoryComponentDependency> {

    private let authenticationResult: AuthenticationResult
    private let didDetectDomainConflict: Bool
    private let howToChangeEmailURL: URL
    private let howToDeleteAccountURL: URL
    private let bridge: WireAuthenticationBridge

    init(
        parent: any Scope,
        authenticationResult: AuthenticationResult,
        didDetectDomainConflict: Bool,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        bridge: WireAuthenticationBridge
    ) {
        self.authenticationResult = authenticationResult
        self.didDetectDomainConflict = didDetectDomainConflict
        self.howToChangeEmailURL = howToChangeEmailURL
        self.howToDeleteAccountURL = howToDeleteAccountURL
        self.bridge = bridge

        super.init(parent: parent)
    }

    @MainActor private var viewModel: NoHistoryViewModel {
        NoHistoryViewModel(
            didDetectDomainConflict: didDetectDomainConflict,
            howToChangeEmailURL: howToChangeEmailURL,
            howToDeleteAccountURL: howToDeleteAccountURL,
            onFlowCompletion: { [weak bridge, authenticationResult] in
                bridge?.onFlowCompletion(authenticationResult)
            }
        )
    }

    @MainActor var view: NoHistoryView {
        NoHistoryView(viewModel: viewModel)
    }

}
