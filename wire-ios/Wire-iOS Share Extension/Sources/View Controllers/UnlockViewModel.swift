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

import Foundation

final class UnlockViewModel {

    struct DisplayState {
        let title: String
        let hint: String
        let passcodePlaceholder: String
        let submitButtonTitle: String
        let errorMessage: String?
        let isSubmitEnabled: Bool
    }

    enum Route {
        case submit(passcode: String)
        case none
    }

    private(set) var passcode = ""
    private(set) var isShowingError = false

    var displayState: DisplayState {
        DisplayState(
            title: L10n.ShareExtension.Unlock.titleLabel,
            hint: L10n.ShareExtension.Unlock.hintLabel,
            passcodePlaceholder: L10n.ShareExtension.Unlock.Textfield.placeholder,
            submitButtonTitle: L10n.ShareExtension.Unlock.SubmitButton.title.localizedUppercase,
            errorMessage: isShowingError ? L10n.ShareExtension.Unlock.errorLabel : nil,
            isSubmitEnabled: !passcode.isEmpty && !isShowingError
        )
    }

    func reset() {
        passcode = ""
        isShowingError = false
    }

    func updatePasscode(_ value: String?) {
        passcode = value ?? ""
        isShowingError = false
    }

    func showWrongPasscode() {
        isShowingError = true
    }

    func routeForSubmit() -> Route {
        guard !passcode.isEmpty else { return .none }

        return .submit(passcode: passcode)
    }
}
