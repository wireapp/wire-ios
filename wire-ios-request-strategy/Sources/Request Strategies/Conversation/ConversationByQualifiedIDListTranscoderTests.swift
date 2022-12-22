// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import Foundation

class ConversationByQualifiedIDListTranscoderTests: MessagingTestBase {

    // MARK: - Request generation

    func testRequestGeneration_V1() throws {
        // Given
        let sut = ConversationByQualifiedIDListTranscoder(context: uiMOC)
        let ids: [QualifiedID] = [QualifiedID(uuid: .create(), domain: "example.com")]

        // When
        let request = try XCTUnwrap(sut.request(for: Set(ids), apiVersion: .v1))

        // Then
        XCTAssertEqual(request.path, "/v1/conversations/list/v2")
        XCTAssertEqual(request.method, .methodPOST)

        let payloadString = try XCTUnwrap(request.payload as? String)
        let payloadData = try XCTUnwrap(payloadString.data(using: .utf8))
        let payload = Payload.QualifiedUserIDList(payloadData)
        XCTAssertEqual(payload, Payload.QualifiedUserIDList(qualifiedIDs: ids))
    }

    func testRequestGeneration_V2() throws {
        // Given
        let sut = ConversationByQualifiedIDListTranscoder(context: uiMOC)
        let ids: [QualifiedID] = [QualifiedID(uuid: .create(), domain: "example.com")]

        // When
        let request = try XCTUnwrap(sut.request(for: Set(ids), apiVersion: .v2))

        // Then
        XCTAssertEqual(request.path, "/v2/conversations/list")
        XCTAssertEqual(request.method, .methodPOST)

        let payloadString = try XCTUnwrap(request.payload as? String)
        let payloadData = try XCTUnwrap(payloadString.data(using: .utf8))
        let payload = Payload.QualifiedUserIDList(payloadData)
        XCTAssertEqual(payload, Payload.QualifiedUserIDList(qualifiedIDs: ids))
    }

}
