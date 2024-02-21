//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@testable import WireRequestStrategy

final class SelfSupportedProtocolsRequestBuilderTests: XCTestCase {

    // the api version is just required to build and not influence the tests themselves
    private let defaultAPIVersion: APIVersion = .v4

    // MARK: Transport Request

    func testBuildTransportRequest_givenAPIVersion0_thenDontBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v0)

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertNil(request)
    }

    func testBuildTransportRequest_givenAPIVersion4_thenBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v4)

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertNotNil(request)
    }

    func testBuildTransportRequest_givenAPIVersion5_thenBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v5)

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertNotNil(request)
    }

    func testBuildTransportRequest_thenPathIsSet() {
        // given
        let builder = makeBuilder(apiVersion: .v4)

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertEqual(request?.path, "/v4/self/supported-protocols")
    }

    func testBuildTransportRequest_thenMethodIsPUT() {
        // given
        let builder = makeBuilder()

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertEqual(request?.method, .put)
    }

    func testBuildTransportRequest_thenPayloadIsSet() throws {
        // given
        let builder = makeBuilder(supportedProtocols: [.proteus, .mls])

        // when
        let request = builder.buildTransportRequest()

        // then
        let payload = try XCTUnwrap(request?.payload as? [String: [String]])
        let supportedProtocols = payload["supported_protocols"]
        XCTAssert(supportedProtocols?.contains("proteus") == true)
        XCTAssert(supportedProtocols?.contains("mls") == true)
    }

    func testBuildTransportRequest_thenAPIVersionIsSet() {
        // given
        let builder = makeBuilder(apiVersion: defaultAPIVersion)

        // when
        let request = builder.buildTransportRequest()

        // then
        XCTAssertEqual(request?.apiVersion, defaultAPIVersion.rawValue)
    }

    // MARK: Upstream Request

    func testBuildUpstreamRequest_givenAPIVersion0_thenDontBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v0)

        // when
        let request = builder.buildUpstreamRequest(keys: .init())

        // then
        XCTAssertNil(request)
    }

    func testBuildUpstreamRequest_givenAPIVersion4_thenBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v4)

        // when
        let request = builder.buildUpstreamRequest(keys: .init())

        // then
        XCTAssertNotNil(request)
    }

    func testBuildUpstreamRequest_givenAPIVersion5_thenBuildRequest() {
        // given
        let builder = makeBuilder(apiVersion: .v5)

        // when
        let request = builder.buildUpstreamRequest(keys: .init())

        // then
        XCTAssertNotNil(request)
    }

    func testBuildUpstreamRequest_thenTransportRequestPathIsSet() {
        // given
        let builder = makeBuilder(apiVersion: .v4)

        // when
        let request = builder.buildUpstreamRequest(keys: .init())

        // then
        XCTAssertEqual(request?.transportRequest.path, "/v4/self/supported-protocols")
    }

    func testBuildUpstreamRequest_thenKeysAreSet() {
        // given
        let key = "supportedProtocols"
        let builder = makeBuilder()

        // when
        let request = builder.buildUpstreamRequest(keys: [key])

        // then
        XCTAssertEqual(request?.keys, [key])
    }

    func testBuildUpstreamRequest_thenUserInfo() throws {
        // given
        let builder = makeBuilder(supportedProtocols: [.proteus, .mls])

        // when
        let request = builder.buildUpstreamRequest(keys: .init())

        // then
        XCTAssert(request?.userInfo.isEmpty ==  true)
    }

    // MARK: Helpers

    private func makeBuilder(
        apiVersion: APIVersion? = nil,
        supportedProtocols: Set<MessageProtocol>? = nil
    ) -> SelfSupportedProtocolsRequestBuilder {
        SelfSupportedProtocolsRequestBuilder(
            apiVersion: apiVersion ?? defaultAPIVersion,
            supportedProtocols: supportedProtocols ?? .init()
        )
    }
}
