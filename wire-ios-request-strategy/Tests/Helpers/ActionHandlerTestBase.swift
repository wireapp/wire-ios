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

import UIKit
import XCTest
@testable import WireRequestStrategy

// MARK: - ActionHandlerTestBase

class ActionHandlerTestBase<Action: EntityAction, Handler: ActionHandler<Action>>: MessagingTestBase {
    typealias ValidationBlock = (Result<Action.Result, Action.Failure>) -> Bool

    var action: Action!
    var handler: Handler!

    override func tearDown() {
        action = nil
        handler = nil
        super.tearDown()
    }

    // MARK: Request Generation

    @discardableResult
    func test_itGeneratesARequest<Payload: Equatable>(
        for action: Action,
        expectedPath: String,
        expectedPayload: Payload?,
        expectedMethod: ZMTransportRequestMethod,
        expectedAcceptType: ZMTransportAccept? = nil,
        apiVersion: APIVersion = .v1
    ) throws -> ZMTransportRequest {
        // When
        let request = try XCTUnwrap(handler.request(for: action, apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, expectedMethod)

        if let expectedPayload {
            XCTAssertEqual(request.payload as? Payload, expectedPayload)
        }

        if let expectedAcceptType {
            XCTAssertEqual(request.acceptedResponseMediaTypes, expectedAcceptType)
        }

        return request
    }

    func test_itGeneratesARequest(
        for action: Action,
        expectedPath: String,
        expectedMethod: ZMTransportRequestMethod,
        expectedData: Data?,
        expectedContentType: String?,
        apiVersion: APIVersion = .v1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        // When
        let request = try XCTUnwrap(handler.request(for: action, apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, expectedPath, file: file, line: line)
        XCTAssertEqual(request.method, expectedMethod, file: file, line: line)
        XCTAssertEqual(request.binaryData, expectedData, file: file, line: line)
        XCTAssertEqual(request.binaryDataType, expectedContentType, file: file, line: line)
    }

    func test_itDoesntGenerateARequest(
        action: Action,
        apiVersion: APIVersion,
        validation: @escaping ValidationBlock
    ) {
        // Given
        var action = action

        // Expectation
        expect(action: &action, toPassValidation: validation)

        // When
        let request = handler.request(for: action, apiVersion: apiVersion)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertNil(request)
    }

    // MARK: - Response Handling

    /// This methods helps testing that the sut handles the transport response as expected
    /// - Parameters:
    ///   - action: The action on which to expect validation
    ///   - status: The reponse status
    ///   - payload: The payload returned by the response
    ///   - label: The error label returned in the response payload (won't be included if `payload` is not `nil`)
    ///   - apiVersion: The api version of the response
    ///   - validation: The validation block to perform on the action result
    func test_itHandlesResponse(
        action: Action,
        status: Int,
        payload: ZMTransportData? = nil,
        label: String? = nil,
        apiVersion: APIVersion = .v1,
        file: StaticString = #file,
        line: UInt = #line,
        validation: @escaping ValidationBlock
    ) {
        // Given
        var action = action

        // Expectation
        expect(action: &action, toPassValidation: validation)

        // When
        let response = response(
            status: status,
            payload: payload,
            label: label,
            apiVersion: apiVersion
        )
        syncMOC.performGroupedAndWait {
            self.handler.handleResponse(response, action: action)
        }

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5), file: file, line: line)
    }
}

extension ActionHandlerTestBase {
    struct DefaultEquatable: Equatable {}

    @discardableResult
    func test_itGeneratesARequest(
        for action: Action,
        expectedPath: String,
        expectedMethod: ZMTransportRequestMethod,
        expectedAcceptType: ZMTransportAccept? = nil,
        apiVersion: APIVersion = .v1
    ) throws -> ZMTransportRequest {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: expectedPath,
            expectedPayload: DefaultEquatable?.none,
            expectedMethod: expectedMethod,
            expectedAcceptType: expectedAcceptType,
            apiVersion: apiVersion
        )
    }

    func test_itHandlesResponse(
        status: Int,
        payload: ZMTransportData? = nil,
        label: String? = nil,
        apiVersion: APIVersion = .v1,
        file: StaticString = #file,
        line: UInt = #line,
        validation: @escaping ValidationBlock
    ) {
        guard let action else {
            return XCTFail("action must be set in child class' setup")
        }

        test_itHandlesResponse(
            action: action,
            status: status,
            payload: payload,
            label: label,
            apiVersion: apiVersion,
            file: file,
            line: line,
            validation: validation
        )
    }

    @discardableResult
    func test_itHandlesSuccess(
        status: Int,
        payload: ZMTransportData? = nil,
        apiVersion: APIVersion = .v1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Action.Result? {
        var result: Action.Result?

        test_itHandlesResponse(
            status: status,
            payload: payload,
            apiVersion: apiVersion,
            file: file,
            line: line
        ) {
            guard case let .success(res) = $0 else { return false }
            result = res
            return true
        }

        return result
    }
}

extension ActionHandlerTestBase where Action.Failure: Equatable {
    // MARK: Failures Assessment

    func test_itDoesntGenerateARequest(
        action: Action,
        apiVersion: APIVersion,
        expectedError: Action.Failure
    ) {
        test_itDoesntGenerateARequest(action: action, apiVersion: apiVersion, validation: {
            guard case let .failure(error) = $0 else { return false }
            return error == expectedError
        })
    }

    func test_itHandlesFailure(
        status: Int,
        payload: ZMTransportData? = nil,
        expectedError: Action.Failure,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        test_itHandlesResponse(
            status: status,
            payload: payload,
            file: file,
            line: line
        ) {
            guard case let .failure(error) = $0 else { return false }
            return error == expectedError
        }
    }

    func test_itHandlesFailure(
        status: Int,
        label: String? = nil,
        apiVersion: APIVersion = .v1,
        expectedError: Action.Failure
    ) {
        test_itHandlesResponse(status: status, label: label, apiVersion: apiVersion) {
            guard case let .failure(error) = $0 else { return false }
            return error == expectedError
        }
    }

    func test_itHandlesFailures(_ failures: [FailureCase]) {
        failures.forEach(test_itHandlesFailure)
    }

    func test_itHandlesFailure(_ failure: FailureCase) {
        test_itHandlesFailure(status: failure.status, label: failure.label, expectedError: failure.error)
    }

    struct FailureCase {
        let status: Int
        let error: Action.Failure
        let label: String?

        static func failure(status: Int, error: Action.Failure, label: String? = nil) -> Self {
            .init(status: status, error: error, label: label)
        }
    }
}

extension ActionHandlerTestBase {
    // MARK: Payload Encoding

    func transportData(for payload: (some Encodable)?) -> ZMTransportData? {
        let data = try! JSONEncoder.defaultEncoder.encode(payload)
        return String(bytes: data, encoding: .utf8) as ZMTransportData?
    }
}

extension ActionHandlerTestBase {
    // MARK: - Helpers

    private func expect(
        action: inout Action,
        toPassValidation validateResult: @escaping ValidationBlock
    ) {
        let expectation = customExpectation(description: "didPassValidation")

        action.onResult { result in
            guard validateResult(result) else { return }
            expectation.fulfill()
        }
    }

    private func response(
        status: Int,
        payload: ZMTransportData?,
        label: String?,
        apiVersion: APIVersion
    ) -> ZMTransportResponse {
        var payload = payload

        if payload == nil, let label {
            payload = ["label": label] as ZMTransportData
        }

        return ZMTransportResponse(
            payload: payload,
            httpStatus: status,
            transportSessionError: nil,
            apiVersion: apiVersion.rawValue
        )
    }
}
