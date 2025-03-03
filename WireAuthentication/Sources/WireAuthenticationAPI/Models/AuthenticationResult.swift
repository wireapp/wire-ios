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

/// The result of an authentication flow.

public struct AuthenticationResult: Equatable {

    /// The user id of whom the token belongs.

    public let userID: UUID

    /// The authentication cookies.

    public let cookies: [HTTPCookie]

    /// A token used to make authenticated requests to the backend if available.

    public let accessToken: AccessToken?

    public init(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?
    ) {
        self.userID = userID
        self.cookies = cookies
        self.accessToken = accessToken
    }

}
