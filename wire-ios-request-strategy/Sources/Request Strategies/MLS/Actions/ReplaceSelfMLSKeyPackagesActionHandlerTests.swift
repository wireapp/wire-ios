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

import Foundation
@testable import WireRequestStrategy
import XCTest

class ReplaceSelfMLSKeyPackagesActionHandlerTests: ActionHandlerTestBase<ReplaceSelfMLSKeyPackagesAction, ReplaceSelfMLSKeyPackagesActionHandler> {

    let clientId = UUID().transportString()
    let keyPackages = ["a2V5IHBhY2thZ2UgZGF0YQo="]
    let ciphersuite = MLSCipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519

    override func setUp() {
        super.setUp()
        action = ReplaceSelfMLSKeyPackagesAction(
            clientID: clientId,
            keyPackages: keyPackages,
            ciphersuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        handler = ReplaceSelfMLSKeyPackagesActionHandler(context: syncMOC)
    }

    // MARK: - Request generation

    func test_itGeneratesARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: action,
            expectedPath: "/v5/mls/key-packages/self/\(clientId)?ciphersuites=\(ciphersuite.rawValue)",
            expectedPayload: ["key_packages": keyPackages],
            expectedMethod: .put,
            apiVersion: .v5
        )
    }

    func test_itDoesntGenerateRequests_APIBelowV5() {
        // when the endpoint is unavailable
        [.v0, .v1, .v2, .v3, .v4].forEach {
            test_itDoesntGenerateARequest(
                action: action,
                apiVersion: $0,
                expectedError: .endpointUnavailable
            )
        }

        // when there are empty parameters
        test_itDoesntGenerateARequest(
            action: ReplaceSelfMLSKeyPackagesAction(clientID: "", keyPackages: [], ciphersuite: ciphersuite),
            apiVersion: .v5,
            expectedError: .invalidParameters
        )
    }

    // MARK: - Response handling

    func test_itHandlesSuccess() {
        test_itHandlesSuccess(status: 201)
    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 400, error: .mlsProtocolError, label: "mls-protocol-error"),
            .failure(status: 400, error: .invalidBodyOrCiphersuites),
            .failure(status: 403, error: .mlsIdentityMismatch, label: "mls-identity-mismatch"),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }

}
