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

public import Foundation

import WireLegacyLogging

/// The domain redirect configuration.

public struct DomainRegistrationConfiguration: Equatable, Sendable {

    /// The `URL` of the on-prem backend.

    public let backendURL: URL?

    /// The configuration value that explains the appropriate login/registration flow.

    public let domainRedirect: DomainRedirect

    /// Whether the email is already in use on the cloud.

    public let isCloudAccountAlreadyRegistered: Bool?

    /// SSO code.

    public let ssoCode: UUID?

    public init(
        backendURLString: String?,
        domainRedirect: DomainRedirect,
        isCloudAccountAlreadyRegistered: Bool?,
        ssoCodeString: String?
    ) {
        self.backendURL = backendURLString.flatMap { urlString in
            if let url = URL(string: urlString) {
                return url
            } else {
                WireLogger.authentication.error("Invalid backend URL format: \(urlString)")
                return nil
            }
        }

        self.domainRedirect = domainRedirect
        self.isCloudAccountAlreadyRegistered = isCloudAccountAlreadyRegistered

        self.ssoCode = ssoCodeString.flatMap { uuidString in
            if let uuid = UUID(uuidString: uuidString) {
                return uuid
            } else {
                WireLogger.authentication.error("Invalid SSO code format: \(uuidString)")
                return nil
            }
        }
    }

}
