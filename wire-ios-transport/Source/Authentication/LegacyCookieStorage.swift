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
import WireLogging

public protocol CookieStorageProtocol: Sendable {

    func storeCookies(_ cookies: [HTTPCookie]) throws
    func fetchCookies() throws -> [HTTPCookie]
    func removeCookies() throws
}

private let cookieName = "zuid"

@objc
public class LegacyCookieStorage: NSObject {

    @objc
    public let userIdentifier: UUID

    private let cookieStorage: any CookieStorageProtocol

    public init(
        userIdentifier: UUID,
        cookieStorage: any CookieStorageProtocol
    ) {
        self.userIdentifier = userIdentifier
        self.cookieStorage = cookieStorage
        super.init()
    }

    // MARK: - Public API

    @objc
    public func storeCookies(_ cookies: [HTTPCookie]) throws {
        try cookieStorage.storeCookies(cookies)
    }

    @objc
    public func removeCookies() throws {
        try cookieStorage.removeCookies()
    }

    @objc
    public var authenticationCookieExpirationDate: Date? {
        let cookies = (try? cookieStorage.fetchCookies()) ?? []
        for cookie in cookies {
            if cookie.name == cookieName {
                return cookie.expiresDate
            }
        }
        return nil
    }

    @objc
    public var hasAuthenticationCookie: Bool {
        authenticationCookieExpirationDate != nil
    }

    // MARK: - HTTPCookie

    @objc(setCookieDataFromResponse:forURL:)
    public func setCookieData(from response: HTTPURLResponse, for url: URL) {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:], for: url)
        if cookies.isEmpty {
            return
        }

        let properties = cookies.compactMap(\.properties)

        guard (properties.first?[.name] as? String) == cookieName else {
            return
        }

        do {
            try storeCookies(cookies)
        } catch {
            WireLogger.authentication.error("Failed to store cookies: \(error)")
        }
    }

    @objc(setRequestHeaderFieldsOnRequest:)
    public func setRequestHeaderFields(on request: NSMutableURLRequest) {
        let cookies = (try? cookieStorage.fetchCookies()) ?? []

        for (field, value) in HTTPCookie.requestHeaderFields(with: cookies) {
            request.addValue(value, forHTTPHeaderField: field)
        }
    }

}
