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
        let transportData = MockAcmeResponse().acmeDirectory().transportData
        mockHttpClient?.mockResponse1 = ZMTransportResponse(payload: transportData,
                                                           httpStatus: 200,
                                                           transportSessionError: nil,
                                                           apiVersion: 0)
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
            guard  let acmeDirectoryData = try await acmeClient?.getACMEDirectory() else {
                return XCTFail("Failed to get ACME directory.")
            }
        } catch NetworkError.invalidRequest {
            // then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }
    }
//
//    func test1() async throws {
//        // expectation
//        let expectedNonce = "ACMENonce"
//
//        // given
//        let path = "https://acme.elna.wire.link/acme/defaultteams/new-nonce"
//        let mock = ZMTransportResponse(payload: nil,
//                                       httpStatus: 200,
//                                       transportSessionError: nil,
//                                       apiVersion: 0)
//        mockHttpClient?.mockResponse1 = mock
//        mock.rawResponse = HTTPURLResponse(
//            url: URL(string: "wire.com")!,
//            statusCode: 200,
//            httpVersion: "",
//            headerFields: ["Content-Type": "application/json"]
//        )!
//
//        // when
//        let nonce = try await acmeClient?.getACMENonce(url: path)
//
//        // then
//        XCTAssertEqual(nonce, expectedNonce)
//    }

    func test11_No_header() async throws {
        // given

        // when
        let acmeDirectoryData = try await acmeClient?.getACMENonce(url: "")

        // then

    }

    func test2() async throws {
        // given

        // when
        let acmeDirectoryData = try await acmeClient?.sendACMERequest(url: "", requestBody: Data())

        // then

    }

    func test22_NoRelyNonce() async throws {
        // given

        // when
        let acmeDirectoryData = try await acmeClient?.sendACMERequest(url: "", requestBody: Data())

        // then

    }

    func test22_No_location() async throws {
        // given

        // when
        let acmeDirectoryData = try await acmeClient?.sendACMERequest(url: "", requestBody: Data())

        // then

    }

}

extension AcmeDirectoriesResponse {

    var transportData: ZMTransportData {
        let encoded = try! JSONEncoder.defaultEncoder.encode(self)
        return try! JSONSerialization.jsonObject(with: encoded, options: []) as! ZMTransportData
    }

}
