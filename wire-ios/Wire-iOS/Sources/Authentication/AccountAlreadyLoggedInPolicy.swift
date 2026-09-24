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

/// Decides whether an `AuthenticationResult` for a known account should be
/// treated as "already logged in" (blocking with an error), versus letting
/// it through to the multi-ingress SSO identity-provider-change flow, which
/// has its own safeguard around purging retained data for an active account.

enum AccountAlreadyLoggedInPolicy {

    /// Whether the backend-reported SSO identity provider for this login
    /// differs from the one last recorded for the account, meaning the
    /// multi-ingress IdP-change flow should run instead of treating this as
    /// a plain re-login.

    static func hasIdentityProviderChanged(
        ssoIdpChangeDetectionEnabled: Bool,
        multiIngressIdentityProviderID: UUID?,
        lastSSOIdentityProviderID: UUID?
    ) -> Bool {
        guard ssoIdpChangeDetectionEnabled, let identityProviderID = multiIngressIdentityProviderID else {
            return false
        }

        return lastSSOIdentityProviderID != identityProviderID
    }

    static func isAlreadyLoggedIn(
        isAccountActive: Bool,
        ssoIdpChangeDetectionEnabled: Bool,
        multiIngressIdentityProviderID: UUID?,
        lastSSOIdentityProviderID: UUID?
    ) -> Bool {
        if hasIdentityProviderChanged(
            ssoIdpChangeDetectionEnabled: ssoIdpChangeDetectionEnabled,
            multiIngressIdentityProviderID: multiIngressIdentityProviderID,
            lastSSOIdentityProviderID: lastSSOIdentityProviderID
        ) {
            return false
        }

        return multiIngressIdentityProviderID == nil || isAccountActive
    }

}
