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

import Foundation

/// The domain redirect configuration.

public struct DomainRegistrationConfiguration: Equatable, Sendable {

    /// The `URL` of the backend.

    public let backendUrl: URL?

    /// The configuration value that explains the appropriate login/registration flow.

    public let domainRedirect: DomainRedirect

    /// Whether the email is already in use on the cloud.

    public let dueToExistingAccount: Bool?

    /// SSO code.

    public let ssoCode: UUID?

    public init(
        backendUrlStr: String?,
        domainRedirect: DomainRedirect,
        dueToExistingAccount: Bool?,
        ssoCodeStr: String?
    ) {
        if let backendUrlStr {
            self.backendUrl = URL(string: backendUrlStr)
        } else {
            self.backendUrl = nil
        }
        self.domainRedirect = domainRedirect
        self.dueToExistingAccount = dueToExistingAccount
        if let ssoCodeStr {
            self.ssoCode = UUID(uuidString: ssoCodeStr)
        } else {
            self.ssoCode = nil
        }
    }

}
