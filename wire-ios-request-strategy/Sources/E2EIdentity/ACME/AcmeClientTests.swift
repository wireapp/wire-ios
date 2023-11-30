//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class AcmeClientTests: ZMTBaseTest {

    var acmeClient: AcmeClient?
    var mockHttpClient: MockHttpClient?
    let backendDomainBackup = BackendInfo.domain

    override func setUp() {
        super.setUp()

        mockHttpClient = MockHttpClient()
        if let mockHttpClient = mockHttpClient {
            acmeClient = AcmeClient(httpClient: mockHttpClient)
        }
    }

    override func tearDown() {
        acmeClient = nil
        mockHttpClient = nil
        BackendInfo.domain = backendDomainBackup

        super.tearDown()
    }

    func testThatTheResponseContainsAcmeDirectory_OnSuccess() async throws {
        // expectation
        let expectedAcmeDirectory = MockAcmeResponse().acmeDirectory()

        // given
        BackendInfo.domain = "acme.elna.wire.link"

        // mock
        let acmeDirectory = MockAcmeResponse().acmeDirectory()
        let acmeDirectoryData = try! JSONEncoder.defaultEncoder.encode(acmeDirectory)
        mockHttpClient?.mockResponse = (acmeDirectoryData, URLResponse())

        // when
        guard  let acmeDirectoryData = try await acmeClient?.getACMEDirectory() else {
            return XCTFail("Failed to get ACME directory.")
        }

        guard let acmeDirectory = try? JSONDecoder.defaultDecoder.decode(AcmeDirectoriesResponse.self, from: acmeDirectoryData) else {
            return XCTFail("Failed to decode.")
        }

        // then
        XCTAssertEqual(acmeDirectory, expectedAcmeDirectory)
    }

    func testThatItThrowsAnError_WhenDomainIsNil() async throws {
        do {
            // given
            BackendInfo.domain = nil
            // when
            guard let acmeDirectoryData = try await acmeClient?.getACMEDirectory() else {
                return XCTFail("Failed to get ACME directory.")
            }
        } catch NetworkError.errorEncodingRequest {
            // then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }

    func testThatResponseHeaderContainsNonce() async throws {
        // expectation
        let expectedNonce = "ACMENonce"

        // given
        let path = "https://acme.elna.wire.link/acme/defaultteams/new-nonce"

        // mock
        let response = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Replay-Nonce": expectedNonce]
        )!
        mockHttpClient?.mockResponse = (Data(), response)

        // when
        let nonce = try await acmeClient?.getACMENonce(path: path)

        // then
        XCTAssertEqual(nonce, expectedNonce)
    }

    func testThatResponseHeaderDoesNotContainNonce_WhenNoHeaderFields() async throws {
        // expectation
        let expectedNonce = "ACMENonce"

        // given
        let path = "https://acme.elna.wire.link/acme/defaultteams/new-nonce"

        // mock
        let response = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: [:]
        )!
        mockHttpClient?.mockResponse = (Data(), response)

        do {
            // when
            let nonce = try await acmeClient?.getACMENonce(path: path)
        } catch NetworkError.errorDecodingResponseNew {
            // then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }

    func testThatItSendsACMERequest() async throws {
        // expectation
        let headerNonce = "ACMENonce"
        let headerLocation = "Location"
        let response = Data()
        let expectation = ACMEResponse(nonce: headerNonce, location: headerLocation, response: response)

        // given
        let path = "https://acme.elna.wire.link/acme/defaultteams/new-account"
        let requestBody =  Data()

        // mock
        let mockResponse = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Replay-Nonce": headerNonce, "location": headerLocation]
        )!
        let mockData = Data()
        mockHttpClient?.mockResponse = (mockData, mockResponse)

        do {
            // when
            let acmeResponse = try await acmeClient?.sendACMERequest(path: path, requestBody: requestBody)
            // then
            XCTAssertEqual(acmeResponse, expectation)
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }

    func testThatItDoesNotSendACMERequest_WhenNoNonceInTheHeader() async throws {
        // expectation
        let headerNonce = "ACMENonce"
        let headerLocation = "Location"
        let expectation = ACMEResponse(nonce: headerNonce, location: headerLocation, response: Data())

        // given
        let path = "https://acme.elna.wire.link/acme/defaultteams/new-account"

        // mock
        let mockResponse = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["location": headerLocation]
        )!
        let mockData = Data()
        mockHttpClient?.mockResponse = (mockData, mockResponse)

        do {
            // when
            let acmeResponse = try await acmeClient?.sendACMERequest(path: path, requestBody: Data())
        } catch NetworkError.errorDecodingResponseNew {
            // then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }

    func testThatItDoesNotSendACMERequest_WhenNoLocationInTheHeader() async throws {
        // expectation
        let headerNonce = "ACMENonce"
        let headerLocation = "Location"
        let expectation = ACMEResponse(nonce: headerNonce, location: headerLocation, response: Data())

        // given
        let path = "https://acme.elna.wire.link/acme/defaultteams/new-account"

        // mock
        let mockResponse = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: ["Replay-Nonce": headerNonce]
        )!
        let mockData = Data()
        mockHttpClient?.mockResponse = (mockData, mockResponse)

        do {
            // when
            let acmeResponse = try await acmeClient?.sendACMERequest(path: path, requestBody: Data())
        } catch NetworkError.errorDecodingResponseNew {
            // then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }

}

class MockHttpClient: HttpClientCustom {

    var mockResponse: (Data, URLResponse)?

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        guard let mockResponse = mockResponse else {
            throw NetworkError.errorDecodingResponseNew(mockResponse!.1)
        }
        return mockResponse
    }

}

private class MockAcmeResponse {

    func acmeDirectory() -> AcmeDirectoriesResponse {
        return AcmeDirectoriesResponse(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                       newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                       newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order",
                                       revokeCert: "https://acme.elna.wire.link/acme/defaultteams/revoke-cert",
                                       keyChange: "https://acme.elna.wire.link/acme/defaultteams/key-change")

    }

}
