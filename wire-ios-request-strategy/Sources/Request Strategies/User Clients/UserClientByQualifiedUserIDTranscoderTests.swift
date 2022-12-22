// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

class UserClientByQualifiedUserIDTranscoderTests: MessagingTestBase {

    var sut: UserClientByQualifiedUserIDTranscoder!
    let id1 = QualifiedID(uuid: .create(), domain: "foo.com")
    let id2 = QualifiedID(uuid: .create(), domain: "bar.com")

    override func setUp() {
        super.setUp()
        sut = UserClientByQualifiedUserIDTranscoder(managedObjectContext: uiMOC)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    typealias RequestPayload = UserClientByQualifiedUserIDTranscoder.RequestPayload

    func payload(from request: ZMTransportRequest) throws -> RequestPayload? {
        let payloadString = try XCTUnwrap(request.payload as? String)
        let payloadData = try XCTUnwrap(payloadString.data(using: .utf8))
        return RequestPayload(payloadData)
    }

    typealias ResponsePayload = UserClientByQualifiedUserIDTranscoder.ResponsePayload

    func payload(from response: ZMTransportResponse) throws -> ResponsePayload? {
        return ResponsePayload(response)
    }

    // MARK: - Request generation

    func test_requestGenerationV0() throws {
        // Given
        let apiVersion = APIVersion.v0

        // When
        let request = sut.request(for: [id1, id2], apiVersion: apiVersion)

        // Then
        XCTAssertNil(request)
    }

    func test_requestGenerationV1() throws {
        // Given
        let apiVersion = APIVersion.v1

        // When
        let request = try XCTUnwrap(sut.request(for: [id1, id2], apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, "/v1/users/list-clients/v2")
        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.apiVersion, 1)

        let payload = try payload(from: request)
        XCTAssertEqual(payload, RequestPayload(qualifiedIDs: [id1, id2]))
    }

    func test_requestGenerationV2() throws {
        // Given
        let apiVersion = APIVersion.v2

        // When
        let request = try XCTUnwrap(sut.request(for: [id1, id2], apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, "/v2/users/list-clients")
        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.apiVersion, 2)

        let payload = try payload(from: request)
        XCTAssertEqual(payload, RequestPayload(qualifiedIDs: [id1, id2]))
    }

}
