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

import Testing
import WireTransport
import WireTransportSupport

struct LegacyCookieStorageTests {

    let cookiesStorage = StubCookieStorage()
    let sut: LegacyCookieStorage

    init() {
        self.sut = LegacyCookieStorage(userIdentifier: UUID(), cookieStorage: cookiesStorage)
    }

    @Test
    func `storeCookies updates the underlying cookie storage`() throws {
        // given
        let cookies = HTTPCookie.validCookies()
        cookiesStorage.cookies = []

        // when
        try sut.storeCookies(cookies)

        // then
        #expect(cookiesStorage.cookies == cookies)
    }

    @Test
    func `removeCookies clears the underlying cookie storage`() throws {
        // given
        cookiesStorage.cookies = HTTPCookie.validCookies()

        // when
        try sut.removeCookies()

        // then
        #expect(cookiesStorage.cookies.isEmpty)
    }

    @Test
    func `authenticationCookieExpirationDate returns the expiry date of the first authentication cookie`() throws {
        // given
        cookiesStorage.cookies = [
            HTTPCookie.validCookies(string: "yuid=aaa; Expires=Thu, 08-Apr-2026 14:00:00 GMT"),
            HTTPCookie.validCookies(string: "zuid=bbb; Expires=Thu, 09-Apr-2026 15:00:00 GMT"), // <--- This cookie
            HTTPCookie.validCookies(string: "zuid=ccc; Expires=Fri, 10-Apr-2026 16:00:00 GMT"),
        ].flatMap { $0 }

        // when
        let expiration = sut.authenticationCookieExpirationDate

        // then
        #expect(expiration == ISO8601DateFormatter().date(from: "2026-04-09T15:00:00Z")!)
    }

    @Test(arguments: [
        [],
        HTTPCookie.validCookies(string: "yuid=aaa; Expires=Thu, 08-Apr-2026 14:00:00 GMT")
    ])
    func `authenticationCookieExpirationDate returns nil when no authentication cookie`(cookies: [HTTPCookie]) throws {
        // given
        cookiesStorage.cookies = cookies

        // when, then
        #expect(sut.authenticationCookieExpirationDate == nil)
    }

    @Test
    func `hasAuthenticationCookie returns true when a zuid cookie is stored`() {
        // given
        cookiesStorage.cookies = HTTPCookie.validCookies()

        // when, then
        #expect(sut.hasAuthenticationCookie)
    }

    @Test
    func `hasAuthenticationCookie returns true even when the cookie has expired`() {
        // given
        cookiesStorage.cookies = HTTPCookie.validCookies(
            string: "zuid=expired; Expires=Thu, 01-Jan-2020 00:00:00 GMT"
        )

        // when, then
        #expect(sut.hasAuthenticationCookie)
    }

    @Test(arguments: [
        [],
        HTTPCookie.validCookies(string: "yuid=aaa; Expires=Thu, 08-Apr-2026 14:00:00 GMT")
    ])
    func `hasAuthenticationCookie returns false when no zuid cookie is stored`(cookies: [HTTPCookie]) {
        // given
        cookiesStorage.cookies = cookies

        // when, then
        #expect(!sut.hasAuthenticationCookie)
    }

    @Test
    func `setRequestHeaderFields sets the Cookie header from stored cookies`() {
        // given
        cookiesStorage.cookies = HTTPCookie.validCookies(string: "zuid=bbb; Expires=Thu, 09-Apr-2026 15:00:00 GMT")
        let request = NSMutableURLRequest(url: URL(string: "https://example.com/access")!)

        // when
        sut.setRequestHeaderFields(on: request)

        // then
        #expect(request.value(forHTTPHeaderField: "Cookie") == "zuid=bbb")
    }

    @Test
    func `setRequestHeaderFields does nothing when no cookies are stored`() {
        // given
        cookiesStorage.cookies = []
        let request = NSMutableURLRequest(url: URL(string: "https://example.com/access")!)

        // when
        sut.setRequestHeaderFields(on: request)

        // then
        #expect(request.value(forHTTPHeaderField: "Cookie") == nil)
    }

    @Test
    func `setCookieData stores cookies from a response with a zuid cookie`() {
        // given
        let url = URL(string: "https://example.com/login")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Set-Cookie": "zuid=abc123; Expires=Sun, 21-Jul-2030 09:06:45 GMT; Domain=wire.com"]
        )!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        #expect(cookiesStorage.cookies.first?.name == "zuid")
        #expect(cookiesStorage.cookies.first?.value == "abc123")
    }

    @Test
    func `setCookieData does nothing when response has no Set-Cookie header`() {
        // given
        let url = URL(string: "https://example.com/login")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        #expect(cookiesStorage.cookies.isEmpty)
    }

    @Test
    func `setCookieData does nothing when response has a non zuid cookie`() {
        // given
        let url = URL(string: "https://example.com/login")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Set-Cookie": "foo=bar; Expires=Sun, 21-Jul-2030 09:06:45 GMT; Domain=wire.com"]
        )!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        #expect(cookiesStorage.cookies.isEmpty)
    }

}
