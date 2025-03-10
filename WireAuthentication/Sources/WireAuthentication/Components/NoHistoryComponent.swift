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

    var howToChangeEmailURL: URL { get }
    var howToDeleteAccountURL: URL { get }

}

class NoHistoryComponent: Component<NoHistoryComponentDependency> {

    @MainActor
    private func viewModel(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        didDetectDomainConflict: Bool,
        howToChangeEmailURL: URL,
        howToDeleteAccountURL: URL,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void
    ) -> NoHistoryViewModel {
        NoHistoryViewModel(
            userID: userID,
            cookies: cookies,
            accessToken: accessToken,
            didDetectDomainConflict: didDetectDomainConflict,
            howToChangeEmailURL: howToChangeEmailURL,
            howToDeleteAccountURL: howToDeleteAccountURL,
            onFlowCompletion: onFlowCompletion
        )
    }

    @MainActor
    func view(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        didDetectDomainConflict: Bool,
        onFlowCompletion: @escaping (AuthenticationResult) -> Void
    ) -> NoHistoryView {
        NoHistoryView(
            viewModel: viewModel(
                userID: userID,
                cookies: cookies,
                accessToken: accessToken,
                didDetectDomainConflict: didDetectDomainConflict,
                howToChangeEmailURL: dependency.howToChangeEmailURL,
                howToDeleteAccountURL: dependency.howToDeleteAccountURL,
                onFlowCompletion: onFlowCompletion
            )
        )
    }

}
