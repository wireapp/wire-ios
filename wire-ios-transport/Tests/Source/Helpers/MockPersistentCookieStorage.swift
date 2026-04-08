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
import WireTransport

final class MockPersistentCookieStorage: NSObject, PersistentCookieStorageProtocol {

    var userIdentifier: UUID

    var storedCookies: [HTTPCookie]?

    @objc
    init(userIdentifier: UUID) {
        self.userIdentifier = userIdentifier
    }

    func authenticationCookies() -> [HTTPCookie]? {
        storedCookies
    }

    func setAuthenticationCookies(_ cookies: [HTTPCookie]) {
        storedCookies = cookies
    }

    func removeCookies() {
        storedCookies = nil
    }

    var authenticationCookieExpirationDate: Date? {
        storedCookies?
            .first { $0.name == "zuid" }?
            .expiresDate
    }

    var hasAuthenticationCookie: Bool {
        authenticationCookieExpirationDate != nil
    }

    func setCookieData(from response: HTTPURLResponse, for url: URL) {
        let cookies = HTTPCookie.cookies(
            withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:],
            for: url
        )
        guard !cookies.isEmpty,
              let name = cookies.first?.properties?[.name] as? String,
              name == "zuid"
        else { return }
        setAuthenticationCookies(cookies)
    }

    func setRequestHeaderFields(on request: NSMutableURLRequest) {
        guard let cookies = authenticationCookies() else { return }
        for (field, value) in HTTPCookie.requestHeaderFields(with: cookies) {
            request.addValue(value, forHTTPHeaderField: field)
        }
    }

}
