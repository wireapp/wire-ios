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

/// Email credentials for a user.

public struct EmailCredentials: Equatable, Hashable, Sendable {

    /// The user's email address.

    public let email: String

    /// The plaintext password.

    public let password: String

    /// A second factor authentication code.

    public let verificationCode: String?

    public init(
        email: String,
        password: String,
        verificationCode: String?
    ) {
        self.email = email
        self.password = password
        self.verificationCode = verificationCode
    }

}
