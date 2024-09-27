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
import WireDataModel

// MARK: - AuthenticationPrefilledCredentials

/// An object holding the configuration of the login prefill.
struct AuthenticationPrefilledCredentials: Equatable {
    /// The raw credentials value.
    let credentials: LoginCredentials

    /// Whether the credentials are expired.
    let isExpired: Bool
}

// MARK: - LogInStepDescription

/// An authentication step to ask the user for login credentials.
final class LogInStepDescription: AuthenticationStepDescription {
    // MARK: Lifecycle

    init() {
        self.backButton = BackButtonDescription()
        self.mainView = EmptyViewDescription()
        self.headline = L10n.Localizable.Registration.Signin.title
        self.subtext = nil
        self.secondaryView = nil
        self.footerView = nil
    }

    // MARK: Internal

    let backButton: BackButtonDescription?
    let mainView: ViewDescriptor & ValueSubmission
    let headline: String
    let subtext: NSAttributedString?
    let secondaryView: AuthenticationSecondaryViewDescription?
    let footerView: AuthenticationFooterViewDescription?
}
