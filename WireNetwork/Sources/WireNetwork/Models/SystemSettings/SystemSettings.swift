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

/// System-wide settings exposed by the backend.

public struct SystemSettings: Equatable, Sendable {

    /// Whether nomad profiles are enabled.

    public let nomadProfiles: Bool

    /// Whether MLS can be enabled.

    public let setEnableMls: Bool

    /// Whether user creation is restricted.

    public let setRestrictUserCreation: Bool

    /// Whether clients should compare the stored SSO IdP ID with the IdP ID of the
    /// current login and keep existing locally decrypted messages when they match.

    public let ssoIdpChangeDetectionEnabled: Bool

    public init(
        nomadProfiles: Bool = false,
        setEnableMls: Bool,
        setRestrictUserCreation: Bool,
        ssoIdpChangeDetectionEnabled: Bool
    ) {
        self.nomadProfiles = nomadProfiles
        self.setEnableMls = setEnableMls
        self.setRestrictUserCreation = setRestrictUserCreation
        self.ssoIdpChangeDetectionEnabled = ssoIdpChangeDetectionEnabled
    }

}
