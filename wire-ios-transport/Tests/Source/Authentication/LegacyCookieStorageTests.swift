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

import XCTest
import WireTransport
import WireTransportSupport

final class LegacyCookieStorageTests: XCTestCase {

    private var userIdentifier: UUID!
    private var sut: LegacyCookieStorage!

    override func setUp() {
        super.setUp()
        userIdentifier = UUID()
        sut = LegacyCookieStorage(testingWithUserIdentifier: userIdentifier)
    }

    override func tearDown() {
        try? sut.removeCookies()
        sut = nil
        userIdentifier = nil
        super.tearDown()
    }

    // MARK: - Basic storage

    func testThatItDoesNotHaveACookie() {
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatItStoresTheCookie() throws {
        XCTAssertFalse(sut.hasAuthenticationCookie)
        try sut.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatItUpdatesTheCookie() throws {
        XCTAssertFalse(sut.hasAuthenticationCookie)

        try sut.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)

        let otherCookies = HTTPCookie.validCookies(
            string: "zuid=other; Path=/access; Expires=Tue, 06-Oct-2099 11:46:18 GMT; HttpOnly; Secure"
        )
        try sut.storeCookies(otherCookies)
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatItCanDeleteCookies() throws {
        XCTAssertFalse(sut.hasAuthenticationCookie)

        try sut.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)
        try sut.removeCookies()
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatItPersistsCookies() throws {
        try autoreleasepool {
            let sut1 = sut!
            try sut1.storeCookies(HTTPCookie.validCookies())
        }
        let sut2 = sut!
        XCTAssertTrue(sut2.hasAuthenticationCookie)
    }

    // MARK: - Per-user isolation

    func testThatItCanDeleteCookiesForASpecificCookieStorage() throws {
        // given
        let otherUserIdentifier = UUID()
        let sut1 = LegacyCookieStorage(testingWithUserIdentifier: userIdentifier)
        let sut2 = LegacyCookieStorage(testingWithUserIdentifier: otherUserIdentifier)

        try sut1.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut1.hasAuthenticationCookie)
        try sut2.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        try sut1.removeCookies()

        // then
        XCTAssertFalse(sut1.hasAuthenticationCookie)
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        try sut2.removeCookies()
        XCTAssertFalse(sut1.hasAuthenticationCookie)
        XCTAssertFalse(sut2.hasAuthenticationCookie)
    }

    func testThatItCanDeleteAllCookies() throws {
        // given
        let otherUserIdentifier = UUID()
        let sut1 = LegacyCookieStorage(testingWithUserIdentifier: userIdentifier)
        let sut2 = LegacyCookieStorage(testingWithUserIdentifier: otherUserIdentifier)

        try sut1.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut1.hasAuthenticationCookie)
        try sut2.storeCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        try sut1.removeCookies()
        try sut2.removeCookies()

        // then
        XCTAssertFalse(sut1.hasAuthenticationCookie)
        XCTAssertFalse(sut2.hasAuthenticationCookie)
    }

    // MARK: - HTTPCookie

    func testThatWeCanRetrieveTheCookie() {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)

        let headerFields = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Set-Cookie": "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
            "Content-Length": "214"
        ]
        let url = URL(string: "https://zeta.example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        sut.setCookieData(from: response, for: url)
        XCTAssertTrue(sut.hasAuthenticationCookie)

        // when
        let request = NSMutableURLRequest(url: url)
        sut.setRequestHeaderFields(on: request)

        // then
        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Cookie"),
            "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4"
        )
    }

    func testThatWeRetrieveCookieExpirationDate() {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)

        let headerFields = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Set-Cookie": "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
            "Content-Length": "214"
        ]
        let url = URL(string: "https://zeta.example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        sut.setCookieData(from: response, for: url)
        XCTAssertTrue(sut.hasAuthenticationCookie)

        // when
        let dateFormatter = ISO8601DateFormatter()
        let expirationDate = sut.authenticationCookieExpirationDate!

        // then
        XCTAssertEqual(dateFormatter.string(from: expirationDate), "2024-07-21T09:06:45Z")
    }

    func testThatItDoesNotSetACookieDataIfNewCookieIsInvalid() throws {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)
        try sut.storeCookies(HTTPCookie.validCookies())

        let headerFields = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Set-Cookie": "UTTER GARBAGE",
            "Content-Length": "214"
        ]
        let url = URL(string: "https://zeta.example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatItDoesNotStoreNonAuthCookies() {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)

        let headerFields = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Set-Cookie": "zuid.challenge=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
            "Content-Length": "214"
        ]
        let url = URL(string: "https://zeta.example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatItStoresAuthCookies() {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)

        let headerFields = [
            "Date": "Thu, 24 Jul 2014 09:06:45 GMT",
            "Content-Encoding": "gzip",
            "Server": "nginx",
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "file://",
            "Connection": "keep-alive",
            "Set-Cookie": "zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
            "Content-Length": "214"
        ]
        let url = URL(string: "https://zeta.example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    // MARK: - Edge cases

    func testThatExpirationDateIsNilWhenNoCookieIsStored() {
        XCTAssertNil(sut.authenticationCookieExpirationDate)
    }

    func testThatHasAuthenticationCookieIsTrueWhenCookieIsStored() {
        // given
        let headerFields = ["Set-Cookie": "zuid=abc123; Expires=Sun, 21-Jul-2030 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"]
        let url = URL(string: "https://example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!
        sut.setCookieData(from: response, for: url)

        // then
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatHasAuthenticationCookieIsFalseWhenNoCookieIsStored() {
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatSetRequestHeaderFieldsDoesNothingWhenNoCookieIsStored() {
        // given
        let url = URL(string: "https://example.com/api")!
        let request = NSMutableURLRequest(url: url)

        // when
        sut.setRequestHeaderFields(on: request)

        // then
        XCTAssertNil(request.value(forHTTPHeaderField: "Cookie"))
    }

    func testThatSetCookieDataFromResponseDoesNothingWhenNoCookieHeader() {
        // given
        let headerFields = ["Content-Type": "application/json"]
        let url = URL(string: "https://example.com/login")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headerFields)!

        // when
        sut.setCookieData(from: response, for: url)

        // then
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatRemoveCookiesDoesNotFailWhenNothingIsStored() throws {
        try sut.removeCookies()
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

}

import Testing

struct NewLegacyCookieStorageTests {

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
