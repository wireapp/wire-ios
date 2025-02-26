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

protocol VerificationCodeComponentDependency: Dependency {}

class VerificationCodeComponent: Component<VerificationCodeComponentDependency> {

    @MainActor
    func view(email: String, password: String) -> VerificationCodeView {
        VerificationCodeView(
            viewModel: viewModel(
                email: email,
                password: password
            )
        )
    }

    @MainActor
    private func viewModel(email: String, password: String) -> VerificationCodeViewModel {
        VerificationCodeViewModel(
            email: email,
            password: password
        )
    }

}
