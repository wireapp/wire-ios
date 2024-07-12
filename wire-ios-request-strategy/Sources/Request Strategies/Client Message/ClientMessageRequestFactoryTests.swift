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

import WireDataModel
import WireProtos
import WireUtilities
import XCTest

@_spi(MockBackendInfo)
import WireTransport

@testable import WireRequestStrategy

final class ClientMessageRequestFactoryTests: MessagingTestBase {

    override func setUp() {
        super.setUp()
        BackendInfo.enableMocking()
        BackendInfo.apiVersion = .v0
    }

    override func tearDown() {
        BackendInfo.resetMocking()
        super.tearDown()
    }

    // MARK: - Client discovery

    func testThatPathAndMessageAreCorrect_WhenCreatingRequest_WithoutDomain() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let conversationID = UUID()
            let expectedMessage = Proteus_NewOtrMessage(
                withSender: self.selfClient,
                nativePush: false,
                recipients: []
            )

            // WHEN
            let request = ClientMessageRequestFactory().upstreamRequestForFetchingClients(
                conversationId: conversationID,
                domain: nil,
                selfClient: self.selfClient,
                apiVersion: BackendInfo.apiVersion!
            )

            guard let data = request?.binaryData else {
                return XCTFail("request has no binary data")
            }

            let message = try? Proteus_NewOtrMessage(serializedData: data)

            // THEN
            XCTAssertNotNil(request)
            XCTAssertNotNil(message)
            XCTAssertEqual(request?.path, "/conversations/\(conversationID.transportString())/otr/messages")
            XCTAssertEqual(message, expectedMessage)
        }
    }

    func testThatPathAndMessageAreCorrect_WhenCreatingRequest_WithDomain() {
        let apiVersion: APIVersion = .v1
        BackendInfo.apiVersion = apiVersion

        syncMOC.performGroupedAndWait {
            // GIVEN
            let conversationID = UUID()
            let domain = "wire.com"
            let expectedMessage = Proteus_QualifiedNewOtrMessage(
                withSender: self.selfClient,
                nativePush: false,
                recipients: [],
                missingClientsStrategy: .doNotIgnoreAnyMissingClient
            )

            // WHEN
            let request = ClientMessageRequestFactory().upstreamRequestForFetchingClients(
                conversationId: conversationID,
                domain: domain,
                selfClient: self.selfClient,
                apiVersion: apiVersion
            )

            guard let data = request?.binaryData else {
                return XCTFail("request has no binary data")
            }

            let message = try? Proteus_QualifiedNewOtrMessage(serializedData: data)

            // THEN
            XCTAssertNotNil(request)
            XCTAssertNotNil(message)
            XCTAssertEqual(request?.path, "/v1/conversations/\(domain)/\(conversationID.transportString())/proteus/messages")
            XCTAssertEqual(message, expectedMessage)
        }
    }
}
