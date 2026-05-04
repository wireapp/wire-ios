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

import XCTest
@testable import WireRequestStrategy

final class MessageAPITests: XCTestCase {

    var sut: MessageAPI!
    private var mockHTTPClient: MockHTTPClient!
    let errorMessage = "test"

    override func setUpWithError() throws {
        mockHTTPClient = MockHTTPClient()
        sut = MessageAPIV8(httpClient: mockHTTPClient)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockHTTPClient = nil
    }

    func test_allMLS_FailureCases() async throws {
        let failures: [FailureCase] = [
            .failure(
                status: 400,
                error: .mlsGroupConversationMismatch(message: errorMessage),
                label: "mls-group-conversation-mismatch"
            ),
            .failure(
                status: 400,
                error: .mlsClientSenderUserMismatch(message: errorMessage),
                label: "mls-client-sender-user-mismatch"
            ),
            .failure(
                status: 400,
                error: .mlsSelfRemovalNotAllowed(message: errorMessage),
                label: "mls-self-removal-not-allowed"
            ),
            .failure(
                status: 400,
                error: .mlsCommitMissingReferences(message: errorMessage),
                label: "mls-commit-missing-references"
            ),
            .failure(status: 400, error: .mlsProtocolError(message: errorMessage), label: "mls-protocol-error"),
            .failure(status: 400, error: .invalidRequestBody(message: errorMessage)),
            .failure(
                status: 403,
                error: .missingLegalHoldConsent(message: errorMessage),
                label: "missing-legalhold-consent"
            ),
            .failure(status: 403, error: .legalHoldNotEnabled(message: errorMessage), label: "legalhold-not-enabled"),
            .failure(status: 403, error: .accessDenied(message: errorMessage), label: "access-denied"),
            .failure(status: 404, error: .mlsProposalNotFound(message: errorMessage), label: "mls-proposal-not-found"),
            .failure(
                status: 404,
                error: .mlsKeyPackageRefNotFound(message: errorMessage),
                label: "mls-key-package-ref-not-found"
            ),
            .failure(status: 404, error: .noConversation(message: errorMessage), label: "no-conversation"),
            .failure(status: 404, error: .noConversationMember(message: errorMessage), label: "no-conversation-member"),
            .failure(status: 409, error: .mlsStaleMessage, label: "mls-stale-message"),
            .failure(status: 409, error: .mlsClientMismatch, label: "mls-client-mismatch"),
            .failure(
                status: 422,
                error: .mlsUnsupportedProposal(message: errorMessage),
                label: "mls-unsupported-proposal"
            ),
            .failure(
                status: 422,
                error: .mlsUnsupportedMessage(message: errorMessage),
                label: "mls-unsupported-message"
            )
        ]

        for failure in failures {
            try await testSendMLSMessageFailure(failure)
        }
    }

    func testOtherFailure_ReturnsNil() async throws {
        // GIVEN:
        let responseStatus = 999
        let responseLabel = "foo"
        let data = Data()
        let conversationID = QualifiedID.random()
        // WHEN

        mockHTTPClient.transportResponse = ZMTransportResponse(
            payload: ["label": responseLabel, "message": errorMessage] as ZMTransportData,
            httpStatus: responseStatus,
            transportSessionError: nil,
            apiVersion: 8
        )

        do {
            _ = try await sut.sendMLSMessage(message: data, conversationID: conversationID, expirationDate: nil)
        } catch {
            let specificError = try XCTUnwrap(error as? NetworkError)
            XCTAssertEqual(specificError, NetworkError.errorDecodingResponse(mockHTTPClient.transportResponse!))
        }

    }

    func testGroupOutOfSyncFailure() async throws {
        // Given
        let sut = MessageAPIV13(httpClient: mockHTTPClient)
        let userID = QualifiedID.random()
        let payload: [String: Any] = [
            "label": "mls-group-out-of-sync",
            "missing_users": [
                [
                    "id": userID.uuid.transportString(),
                    "domain": userID.domain
                ]
            ]
        ]
        mockHTTPClient.transportResponse = ZMTransportResponse(
            payload: payload as ZMTransportData,
            httpStatus: 409,
            transportSessionError: nil,
            apiVersion: 13
        )

        // When
        do {
            _ = try await sut.sendMLSMessage(
                message: Data(),
                conversationID: .random(),
                expirationDate: nil
            )
        } catch {
            let actualError = try XCTUnwrap(
                error as? SendMLSMessageFailure,
                "unexpected error: \(error)"
            )
            XCTAssertEqual(
                actualError,
                SendMLSMessageFailure.groupOutOfSync(missingUsers: [userID])
            )
        }

    }

    // MARK: - Helpers

    private func testSendMLSMessageFailure(
        _ failureCase: FailureCase,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let data = Data()
        let conversationID = QualifiedID.random()

        mockHTTPClient.transportResponse = ZMTransportResponse(
            payload: ["label": failureCase.label, "message": errorMessage] as ZMTransportData,
            httpStatus: failureCase.status,
            transportSessionError: nil,
            apiVersion: 8
        )

        do {
            _ = try await sut.sendMLSMessage(message: data, conversationID: conversationID, expirationDate: nil)
        } catch {
            let specificError = try XCTUnwrap(
                error as? SendMLSMessageFailure,
                "unexpected error type for \(failureCase)",
                file: file,
                line: line
            )
            XCTAssertEqual(specificError, failureCase.error, file: file, line: line)
        }
    }
}

extension MessageAPITests {
    struct FailureCase: CustomStringConvertible {
        let status: Int
        let error: SendMLSMessageFailure
        let label: String?

        static func failure(status: Int, error: SendMLSMessageFailure, label: String? = nil) -> Self {
            .init(status: status, error: error, label: label)
        }

        var description: String {
            "FailureCase status: \(status), error: \(error), label: \(label ?? "<nil>")"
        }
    }
}

private class MockHTTPClient: HttpClient {
    var transportResponse: ZMTransportResponse?

    func send(_ request: ZMTransportRequest) async -> ZMTransportResponse {
        if let transportResponse {
            return transportResponse
        }
        XCTFail("missing mock")
        fatal("missing mock")
    }
}
