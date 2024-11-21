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

/// Storage for authentication primitives.

public protocol AuthenticationStorage {

    /// Store an access token.
    ///
    /// - Parameter accessToken: The token to store.

    func storeAccessToken(_ accessToken: AccessToken) async

    /// Fetch a stored access token.
    ///
    /// - Returns: The stored access token.

    func fetchAccessToken() async -> AccessToken?

    /// Store cookies.
    ///
    /// - Parameter cookies: The cookies to store.

    func storeCookies(_ cookies: [HTTPCookie]) async throws

    /// Fetch stored cookies.
    ///
    /// - Returns: The stored cookies.

    func fetchCookies() async throws -> [HTTPCookie]

}
