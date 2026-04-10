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

@objc
public class LegacyCookieStorage: NSObject {

    private static let cookieName = "zuid"

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

    /// Stores the given cookies.
    @objc
    public func storeCookies(_ cookies: [HTTPCookie]) throws {
        try cookieStorage.storeCookies(cookies)
    }

    /// Removes all stored cookies for the user.
    @objc
    public func removeCookies() throws {
        try cookieStorage.removeCookies()
    }

    /// The expiration date of the authentication cookie, if it exists.
    public var authenticationCookieExpirationDate: Date? {
        for cookie in fetchCookies() {
            if cookie.name == Self.cookieName {
                return cookie.expiresDate
            }
        }
        return nil
    }

    /// Whether there is an authentication cookie stored.
    ///
    /// - warning: This only checks for the presence of the cookie, not whether it is valid or not.
    @objc
    public var hasAuthenticationCookie: Bool {
        authenticationCookieExpirationDate != nil
    }

    // MARK: - HTTPCookie

    /// Extracts cookies from the given HTTP response and stores them if they match the expected cookie name.
    @objc(setCookieDataFromResponse:forURL:)
    public func setCookieData(from response: HTTPURLResponse, for url: URL) {
        let headerFields = response.allHeaderFields as? [String: String] ?? [:]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)

        guard cookies.first?.name == Self.cookieName else { return }

        do {
            try storeCookies(cookies)
        } catch {
            WireLogger.authentication.error("Failed to store cookies: \(error)")
        }
    }

    /// Adds store cookies on the given request.
    @objc(setRequestHeaderFieldsOnRequest:)
    public func setRequestHeaderFields(on request: NSMutableURLRequest) {
        for (field, value) in HTTPCookie.requestHeaderFields(with: fetchCookies()) {
            request.addValue(value, forHTTPHeaderField: field)
        }
    }

    // MARK: - Helpers

    private func fetchCookies() -> [HTTPCookie] {
        do {
            return try cookieStorage.fetchCookies()
        } catch {
            WireLogger.authentication.error("Failed to fetch cookies: \(error)")
            return []
        }

    }

}
