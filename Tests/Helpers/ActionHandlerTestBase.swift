//
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
import UIKit
@testable import WireRequestStrategy

class ActionHandlerTestBase<Action: EntityAction, Handler: ActionHandler<Action>>: MessagingTestBase {

    typealias Result = Action.Result
    typealias Failure = Action.Failure
    typealias ValidationBlock = (Swift.Result<Result, Failure>) -> Bool

    var action: Action!

    override func tearDown() {
        action = nil
        super.tearDown()
    }

    // MARK: Request Generation

    func test_itGeneratesARequest<Payload: Equatable>(
        for action: Action,
        expectedPath: String,
        expectedPayload: Payload?,
        expectedMethod: ZMTransportRequestMethod,
        apiVersion: APIVersion = .v1
    ) throws {
        // Given
        let sut = Handler(context: syncMOC)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, expectedMethod)
        XCTAssertEqual(request.payload as? Payload, expectedPayload)
    }

    func test_itGeneratesARequest(
        for action: Action,
        expectedPath: String,
        expectedMethod: ZMTransportRequestMethod,
        expectedData: Data,
        expectedContentType: String,
        apiVersion: APIVersion = .v1
    ) throws {
        // Given
        let sut = Handler(context: syncMOC)

        // When
        let request = try XCTUnwrap(sut.request(for: action, apiVersion: apiVersion))

        // Then
        XCTAssertEqual(request.path, expectedPath)
        XCTAssertEqual(request.method, expectedMethod)
        XCTAssertEqual(request.binaryData, expectedData)
        XCTAssertEqual(request.binaryDataType, expectedContentType)
    }

    func test_itDoesntGenerateARequest(
        action: Action,
        apiVersion: APIVersion,
        validation: @escaping ValidationBlock
    ) {
        // Given
        var action = action
        let sut = Handler(context: syncMOC)

        // Expectation
        expect(action: &action, toPassValidation: validation)

        // When
        let request = sut.request(for: action, apiVersion: apiVersion)

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
        validation: @escaping ValidationBlock
    ) {
        // Given
        let sut = Handler(context: syncMOC)
        var action = action

        // Expectation
        expect(action: &action, toPassValidation: validation)

        // When
        let response = self.response(
            status: status,
            payload: payload,
            label: label,
            apiVersion: apiVersion
        )
        sut.handleResponse(response, action: action)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
    }
}

extension ActionHandlerTestBase {

    struct DefaultEquatable: Equatable {}

    func test_itGeneratesARequest(
        for action: Action,
        expectedPath: String,
        expectedMethod: ZMTransportRequestMethod,
        apiVersion: APIVersion = .v1
    ) throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: expectedPath,
            expectedPayload: DefaultEquatable?.none,
            expectedMethod: expectedMethod,
            apiVersion: apiVersion
        )
    }

    func test_itHandlesResponse(
        status: Int,
        payload: ZMTransportData? = nil,
        label: String? = nil,
        validation: @escaping ValidationBlock
    ) {
        guard let action = self.action else {
            return XCTFail("action must be set in child class' setup")
        }

        test_itHandlesResponse(
            action: action,
            status: status,
            payload: payload,
            label: label,
            validation: validation
        )
    }

    @discardableResult
    func test_itHandlesSuccess(status: Int, payload: ZMTransportData? = nil) -> Result? {
        var result: Result?

        test_itHandlesResponse(status: status, payload: payload) {
            guard case .success(let res) = $0 else { return false }
            result = res
            return true
        }

        return result
    }
}

extension ActionHandlerTestBase where Failure: Equatable {

    // MARK: Failures Assessment

    func test_itDoesntGenerateARequest(
        action: Action,
        apiVersion: APIVersion,
        expectedError: Failure
    ) {
        test_itDoesntGenerateARequest(action: action, apiVersion: apiVersion, validation: {
            guard case .failure(let error) = $0 else { return false}
            return error == expectedError
        })
    }

    func test_itHandlesFailure(
        status: Int,
        label: String? = nil,
        expectedError: Failure
    ) {
        test_itHandlesResponse(status: status, label: label) {
            guard case .failure(let error) = $0 else { return false}
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
        let error: Failure
        let label: String?

        static func failure(status: Int, error: Failure, label: String? = nil) -> Self {
            return .init(status: status, error: error, label: label)
        }
    }
}

extension ActionHandlerTestBase {

    // MARK: Payload Encoding

    func transportData<Payload: Encodable>(for payload: Payload?) -> ZMTransportData? {
        let data = try! JSONEncoder().encode(payload)
        return String(bytes: data, encoding: .utf8) as ZMTransportData?
    }
}

extension ActionHandlerTestBase {

    // MARK: - Helpers

    private func expect(
        action: inout Action,
        toPassValidation validateResult: @escaping ValidationBlock
    ) {
        let expectation = self.expectation(description: "didPassValidation")

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

        if payload == nil, let label = label {
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
