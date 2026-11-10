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

import SwiftUI
import WireDesign

package struct TwoFactorAuthenticationPlaceholderView: View {

    package enum Destination {
        case authenticatorApps
        case recoveryCodes
    }

    private let destination: Destination

    package init(destination: Destination) {
        self.destination = destination
    }

    package var body: some View {
        Color(ColorTheme.Backgrounds.background)
            .ignoresSafeArea()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier(identifier)
    }

    private var title: String {
        switch destination {
        case .authenticatorApps:
            L10n.Localizable.TwoFactorAuthentication.AuthenticatorApps.title
        case .recoveryCodes:
            L10n.Localizable.TwoFactorAuthentication.RecoveryCodes.title
        }
    }

    private var identifier: String {
        switch destination {
        case .authenticatorApps:
            "twoFactorAuthenticationAuthenticatorAppsView"
        case .recoveryCodes:
            "twoFactorAuthenticationRecoveryCodesView"
        }
    }
}
