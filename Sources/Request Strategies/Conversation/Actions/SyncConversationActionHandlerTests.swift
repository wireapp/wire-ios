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

import XCTest
@testable import WireRequestStrategy

final class SyncConversationActionHandlerTests: MessagingTestBase {

    typealias RequestPayload = SyncConversationActionHandler.RequestPayload
    typealias ResponsePayload = SyncConversationActionHandler.ResponsePayload

    // MARK: - Request generation

    func test_RequestGeneration_V0() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncConversationAction(qualifiedID: id)

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v0))

        // Then
        XCTAssertEqual(result.path, "/conversations/list/v2")
        XCTAssertEqual(result.method, .methodPOST)
        XCTAssertEqual(result.apiVersion, 0)

        let payload = try XCTUnwrap(RequestPayload(result))
        XCTAssertEqual(payload, RequestPayload(qualified_ids: [id]))
    }

    func test_RequestGeneration_V1() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncConversationAction(qualifiedID: id)

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v1))

        // Then
        XCTAssertEqual(result.path, "/v1/conversations/list/v2")
        XCTAssertEqual(result.method, .methodPOST)
        XCTAssertEqual(result.apiVersion, 1)

        let payload = try XCTUnwrap(RequestPayload(result))
        XCTAssertEqual(payload, RequestPayload(qualified_ids: [id]))
    }

    func test_RequestGeneration_V2() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")
        let action = SyncConversationAction(qualifiedID: id)

        // When
        let result = try XCTUnwrap(sut.request(for: action, apiVersion: .v2))

        // Then
        XCTAssertEqual(result.path, "/v2/conversations/list")
        XCTAssertEqual(result.method, .methodPOST)
        XCTAssertEqual(result.apiVersion, 2)

        let payload = try XCTUnwrap(RequestPayload(result))
        XCTAssertEqual(payload, RequestPayload(qualified_ids: [id]))
    }

    // MARK: - Response handling

    func test_HandleResponse_200_InvalidPayload() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")

        let didFail = expectation(description: "did fail")
        let action = SyncConversationAction(qualifiedID: id) { result in
            // Then
            guard case .failure(.invalidResponsePayload) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }

            didFail.fulfill()
        }

        let response = ZMTransportResponse(
            payload: "invalid" as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: 2
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_HandleResponse_200_ConversationNotFound() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")

        let didFail = expectation(description: "did fail")
        let action = SyncConversationAction(qualifiedID: id) { result in
            // Then
            guard case .failure(.conversationNotFound) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }

            didFail.fulfill()
        }

        let payload = ResponsePayload(found: [], failed: [], not_found: [])
        let payloadString = try XCTUnwrap(payload.payloadString())

        let response = ZMTransportResponse(
            payload: payloadString as ZMTransportData,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: 2
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_HandleResponse_200_Success() throws {
        // Given
        try syncMOC.performGroupedAndWait { context in
            let sut = SyncConversationActionHandler(context: context)
            let id = QualifiedID(uuid: .create(), domain: "example.com")

            let didSucceed = self.expectation(description: "did succeed")
            let action = SyncConversationAction(qualifiedID: id) { result in
                // Then
                guard case .success = result else {
                    XCTFail("unexpected result: \(String(describing: result))")
                    return
                }

                didSucceed.fulfill()
            }

            let conversation = Payload.Conversation(
                qualifiedID: id,
                id: id.uuid,
                type: BackendConversationType.group.rawValue
            )

            let payload = ResponsePayload(found: [conversation], failed: [], not_found: [])
            let payloadString = try XCTUnwrap(payload.payloadString())

            let response = ZMTransportResponse(
                payload: payloadString as ZMTransportData,
                httpStatus: 200,
                transportSessionError: nil,
                apiVersion: 2
            )

            XCTAssertNil(ZMConversation.fetch(with: id.uuid, domain: id.domain, in: context))

            // When
            sut.handleResponse(response, action: action)
            XCTAssert(self.waitForCustomExpectations(withTimeout: 0.5))

            // Then
            XCTAssertNotNil(ZMConversation.fetch(with: id.uuid, domain: id.domain, in: context))
        }
    }

    func test_HandleResponse_400_InvalidBody() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")

        let didFail = expectation(description: "did fail")
        let action = SyncConversationAction(qualifiedID: id) { result in
            // Then
            guard case .failure(.invalidBody) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }

            didFail.fulfill()
        }

        let payload = [
            "label": "invalid-body"
        ]

        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 400,
            transportSessionError: nil,
            apiVersion: 2
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_HandleResponse_UnknownError() throws {
        // Given
        let sut = SyncConversationActionHandler(context: uiMOC)
        let id = QualifiedID(uuid: .create(), domain: "example.com")

        let didFail = expectation(description: "did fail")
        let action = SyncConversationAction(qualifiedID: id) { result in
            // Then
            guard case .failure(.unknownError(code: 999, label: "foo", message: "bar")) = result else {
                XCTFail("unexpected result: \(String(describing: result))")
                return
            }

            didFail.fulfill()
        }

        let payload = [
            "label": "foo",
            "message": "bar"
        ]

        let response = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 999,
            transportSessionError: nil,
            apiVersion: 2
        )

        // When
        sut.handleResponse(response, action: action)
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }

}
