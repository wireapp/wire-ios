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

import AppAuthCore
import XCTest

@testable import Wire

final class WebViewUserAgentTests: XCTestCase {

    var sut: WebViewUserAgent!
    var targetViewController: UIViewController!

    override func setUp() {
        targetViewController = UIViewController()
        sut = WebViewUserAgent(targetViewController: targetViewController)
    }

    override func tearDown() {
        targetViewController = nil
        sut = nil
    }

    func testItPresentsAWebView() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "www.wire.com"))
        let request = MockRequest(
            externalUserAgentRequestURL: url,
            redirectScheme: "wire"
        )
        let session = MockSession()

        // When
        let didPresent = sut.present(
            request,
            session: session
        )

        // Then
        XCTAssertTrue(didPresent)
    }

    func testItCancelsTheOAuthFlow() throws {
        let url = try XCTUnwrap(URL(string: "www.wire.com"))
        let request = MockRequest(
            externalUserAgentRequestURL: url,
            redirectScheme: "wire"
        )
        let session = MockSession()
        let didPresent = sut.present(
            request,
            session: session
        )
        XCTAssertTrue(didPresent)

        // When
        sut.webAuthViewDidCancel()

        // Then
        XCTAssertTrue(session.didCancel)
    }

    func testItResumesTheOAuthFlowWithResult() throws {
        let url = try XCTUnwrap(URL(string: "www.wire.com"))
        let request = MockRequest(
            externalUserAgentRequestURL: url,
            redirectScheme: "wire"
        )
        let session = MockSession()
        let didPresent = sut.present(
            request,
            session: session
        )
        XCTAssertTrue(didPresent)

        // When
        let callbackURL = try XCTUnwrap(URL(string: "wire://complete"))
        sut.webAuthViewDidReceiveCallback(url: callbackURL)

        // Then
        XCTAssertEqual(session.didResumeFlowWithURL, callbackURL)
    }

}

private class MockRequest: OIDExternalUserAgentRequest {

    var mockExternalUserAgentRequestURL: URL
    var mockRedirectScheme: String

    init(
        externalUserAgentRequestURL: URL,
        redirectScheme: String
    ) {
        self.mockExternalUserAgentRequestURL = externalUserAgentRequestURL
        self.mockRedirectScheme = redirectScheme
    }

    func externalUserAgentRequestURL() -> URL! {
        mockExternalUserAgentRequestURL
    }

    func redirectScheme() -> String! {
        mockRedirectScheme
    }

}

private class MockSession: NSObject, OIDExternalUserAgentSession {
    var didCancel = false
    var didResumeFlowWithURL: URL?
    var didFailFlowWithError: Error?

    func cancel() {
        didCancel = true
    }

    func cancel() async {
        didCancel = true
    }

    func resumeExternalUserAgentFlow(with url: URL) -> Bool {
        didResumeFlowWithURL = url
        return true
    }

    func failExternalUserAgentFlowWithError(_ error: any Error) {
        didFailFlowWithError = error
    }

}
