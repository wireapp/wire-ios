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
@testable import WireRequestStrategy

class UploadSelfMLSKeyPackagesActionHandlerTests: ActionHandlerTestBase<UploadSelfMLSKeyPackagesAction, UploadSelfMLSKeyPackagesActionHandler> {

    let domain = "example.com"
    let clientId = UUID().transportString()
    let keyPackages = ["a2V5IHBhY2thZ2UgZGF0YQo="]

    override func setUp() {
        super.setUp()
        action = UploadSelfMLSKeyPackagesAction(clientID: clientId, keyPackages: keyPackages)
    }

    // MARK: - Request generation

    func test_itGeneratesARequest() throws {
        try test_itGeneratesARequest(
            for: UploadSelfMLSKeyPackagesAction(
                clientID: clientId,
                keyPackages: keyPackages
            ),
            expectedPath: "/v1/mls/key-packages/self/\(clientId)",
            expectedPayload: ["key_packages": keyPackages],
            expectedMethod: .methodPOST,
            apiVersion: .v1
        )
    }

    func test_itDoesntGenerateRequests() {
        // when the endpoint is unavailable
        test_itDoesntGenerateARequest(
            action: action,
            apiVersion: .v0,
            expectedError: .endpointUnavailable
        )

        // when there are empty parameters
        test_itDoesntGenerateARequest(
            action: UploadSelfMLSKeyPackagesAction(clientID: "", keyPackages: []),
            apiVersion: .v1,
            expectedError: .emptyParameters
        )
    }

    // MARK: - Response handling

    func test_itHandlesSuccess() {
        test_itHandlesSuccess(status: 201)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .invalidBody),
            .failure(status: 400, error: .mlsProtocolError, label: "mls-protocol-error"),
            .failure(status: 403, error: .identityMismatch, label: "mls-identity-mismatch"),
            .failure(status: 404, error: .clientNotFound),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
