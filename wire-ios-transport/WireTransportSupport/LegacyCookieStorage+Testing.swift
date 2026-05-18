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

import WireTransport

/// An in-memory cookie storage for testing purposes.
public final class StubCookieStorage: CookieStorageProtocol {

    public nonisolated(unsafe) var cookies: [HTTPCookie] = []

    public init() {}

    public func storeCookies(_ cookies: [HTTPCookie], userID: UUID) throws {
        self.cookies = cookies
    }

    public func fetchCookies(userID: UUID) throws -> [HTTPCookie] {
        cookies
    }

    public func removeCookies(userID: UUID) throws {
        cookies = []
    }

}

public extension LegacyCookieStorage {

    @objc
    convenience init(testingWithUserIdentifier userIdentifier: UUID) {
        self.init(
            userIdentifier: userIdentifier,
            cookieStorage: StubCookieStorage()
        )
    }

}
