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

import Testing
@testable import WireNetwork
@testable import WireNetworkSupport

@Suite(.serialized)
class MLSAPITests_SwiftTesting {

    @Test(
        "Test reset MLS broken conversation failures",
        arguments: [
            (
                HTTPStatusCode.badRequest,
                "mls-protocol-error",
                MLSAPIError.mlsProtocolError(message: "")
            ),
            (
                HTTPStatusCode.badRequest,
                "mls-group-id-not-supported",
                MLSAPIError.mlsGroupIdNotSupported(message: "")
            ),
            (
                HTTPStatusCode.badRequest,
                "mls-federated-reset-not-supported",
                MLSAPIError.mlsFederatedResetNotSupported(message: "")
            ),
            (HTTPStatusCode.badRequest, "mls-not-enabled", MLSAPIError.mlsNotEnabled),
            (
                HTTPStatusCode.badRequest,
                "mls-invalid-leaf-node-index",
                MLSAPIError.mlsInvalidLeafNodeIndex
            ),
            (
                HTTPStatusCode.badRequest,
                "mls-invalid-leaf-node-signature",
                MLSAPIError.mlsInvalidLeafNodeSignature
            ),

            (HTTPStatusCode.forbidden, "action-denied", MLSAPIError.actionDenied(message: "")),
            (HTTPStatusCode.forbidden, "access-denied", MLSAPIError.accessDenied(message: "")),
            (HTTPStatusCode.forbidden, "invalid-op", MLSAPIError.invalidOperation(message: "")),

            (HTTPStatusCode.notFound, "no-conversation", MLSAPIError.noConversation(message: "")),

            (HTTPStatusCode.conflict, "mls-stale-message", MLSAPIError.mlsStaleMessage)
        ]
    )
    func testResetBrokenMLSConversations_Failed(
        _ testData: (HTTPStatusCode, String, MLSAPIError)
    ) async {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: testData.0,
            label: testData.1
        )

        // When
        let api = MLSAPIV9(apiService: apiService)

        // Then

        do {
            try await api.resetMLSConversation(epoch: Scaffolding.epoch, groupID: Scaffolding.groupID)
            #expect(Bool(false), "Expected an error to be thrown")
        } catch {
            let error = try? #require(error as? MLSAPIError)
            #expect(error == testData.2)
        }
    }

}

// MARK: Helpers

private enum Scaffolding {

    static let epoch: UInt64 = .random(in: 1 ... 1000)
    static let groupID: String = "123456789"

}
