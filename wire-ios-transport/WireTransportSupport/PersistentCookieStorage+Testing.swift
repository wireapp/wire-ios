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

import WireFoundation
import WireTransport

/// A no-op cookie storage for testing purposes.
private final class StubCookieStorage: CookieStorageProtocol {
    func storeCookies(_ cookies: [HTTPCookie]) throws {}
    func fetchCookies() throws -> [HTTPCookie] { [] }
    func removeCookies() throws {}
}

public extension PersistentCookieStorage {

    @objc
    convenience init(testingWithUserIdentifier userIdentifier: UUID, useCache: Bool) {
        self.init(
            userIdentifier: userIdentifier,
            useCache: useCache,
            cookieStorage: StubCookieStorage()
        )
    }

}
