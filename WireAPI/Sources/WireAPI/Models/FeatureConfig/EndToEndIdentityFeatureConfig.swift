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

/// A configuration for the *End To End Identity* feature.

public struct EndToEndIdentityFeatureConfig: Equatable, Codable {
    /// The feature's status.

    public let status: FeatureConfigStatus

    /// The URL of the ACME server directory service.

    public let acmeDiscoveryURL: String?

    /// The login grace period for OAUTH/OpenID Connect authentication.

    public let verificationExpiration: UInt

    /// The crl proxy URL

    public let crlProxy: String?

    /// Uses proxy on mobile

    public let useProxyOnMobile: Bool
}
