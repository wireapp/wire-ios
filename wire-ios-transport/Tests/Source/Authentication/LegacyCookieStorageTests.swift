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
        sut.removeCookies()
        sut = nil
        userIdentifier = nil
        super.tearDown()
    }

    // MARK: - Basic storage

    func testThatItDoesNotHaveACookie() {
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatItStoresTheCookie() {
        XCTAssertFalse(sut.hasAuthenticationCookie)
        sut.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatItUpdatesTheCookie() {
        XCTAssertFalse(sut.hasAuthenticationCookie)

        sut.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)

        let otherCookies = HTTPCookie.validCookies(
            string: "zuid=other; Path=/access; Expires=Tue, 06-Oct-2099 11:46:18 GMT; HttpOnly; Secure"
        )
        sut.setAuthenticationCookies(otherCookies)
        XCTAssertTrue(sut.hasAuthenticationCookie)
    }

    func testThatItCanDeleteCookies() {
        XCTAssertFalse(sut.hasAuthenticationCookie)

        sut.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut.hasAuthenticationCookie)
        sut.removeCookies()
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

    func testThatItPersistsCookies() {
        autoreleasepool {
            let sut1 = sut!
            sut1.setAuthenticationCookies(HTTPCookie.validCookies())
        }
        let sut2 = sut!
        XCTAssertTrue(sut2.hasAuthenticationCookie)
    }

    // MARK: - Per-user isolation

    func testThatItCanDeleteCookiesForASpecificCookieStorage() {
        // given
        let otherUserIdentifier = UUID()
        let sut1 = LegacyCookieStorage(testingWithUserIdentifier: userIdentifier)
        let sut2 = LegacyCookieStorage(testingWithUserIdentifier: otherUserIdentifier)

        sut1.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut1.hasAuthenticationCookie)
        sut2.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        sut1.removeCookies()

        // then
        XCTAssertFalse(sut1.hasAuthenticationCookie)
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        sut2.removeCookies()
        XCTAssertFalse(sut1.hasAuthenticationCookie)
        XCTAssertFalse(sut2.hasAuthenticationCookie)
    }

    func testThatItCanDeleteAllCookies() {
        // given
        let otherUserIdentifier = UUID()
        let sut1 = LegacyCookieStorage(testingWithUserIdentifier: userIdentifier)
        let sut2 = LegacyCookieStorage(testingWithUserIdentifier: otherUserIdentifier)

        sut1.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut1.hasAuthenticationCookie)
        sut2.setAuthenticationCookies(HTTPCookie.validCookies())
        XCTAssertTrue(sut2.hasAuthenticationCookie)

        // when
        sut1.removeCookies()
        sut2.removeCookies()

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

    func testThatItDoesNotSetACookieDataIfNewCookieIsInvalid() {
        // given
        XCTAssertFalse(sut.hasAuthenticationCookie)
        sut.setAuthenticationCookies(HTTPCookie.validCookies())

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

    func testThatRemoveCookiesDoesNotFailWhenNothingIsStored() {
        sut.removeCookies()
        XCTAssertFalse(sut.hasAuthenticationCookie)
    }

}
