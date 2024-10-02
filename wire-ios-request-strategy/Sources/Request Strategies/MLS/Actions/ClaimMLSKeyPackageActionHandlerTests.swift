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
import WireTransport

class ClaimMLSKeyPackageActionHandlerTests: ActionHandlerTestBase<ClaimMLSKeyPackageAction, ClaimMLSKeyPackageActionHandler> {

    private typealias Payload = ClaimMLSKeyPackageActionHandler.ResponsePayload

    let domain = "example.com"
    let userId = UUID()
    let ciphersuite = MLSCipherSuite.MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
    let excludedSelfCliendId = UUID().transportString()
    let clientId = UUID().transportString()

    override func setUp() {
        super.setUp()
        action = ClaimMLSKeyPackageAction(
            domain: domain,
            userId: userId,
            ciphersuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519
        )
        handler = ClaimMLSKeyPackageActionHandler(context: syncMOC)
    }

    // MARK: - Request generation

    func test_itGeneratesARequest_APIV5() throws {
        try test_itGeneratesARequest(
            for: ClaimMLSKeyPackageAction(
                domain: domain,
                userId: userId,
                ciphersuite: ciphersuite,
                excludedSelfClientId: excludedSelfCliendId
            ),
            expectedPath: "/v5/mls/key-packages/claim/\(domain)/\(userId.transportString())?ciphersuite=\(ciphersuite.rawValue)",
            expectedPayload: ["skip_own": excludedSelfCliendId],
            expectedMethod: .post,
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

        // when the domain is missing
        BackendInfo.domain = nil

        test_itDoesntGenerateARequest(
            action: ClaimMLSKeyPackageAction(
                domain: "",
                userId: userId,
                ciphersuite: ciphersuite,
                excludedSelfClientId: excludedSelfCliendId
            ),
            apiVersion: .v5,
            expectedError: .missingDomain
        )
    }

    // MARK: - Response handling

    func test_itHandlesSuccess() {
        // Given
        let keyPackage = KeyPackage(
            client: clientId,
            domain: domain,
            keyPackage: "a2V5IHBhY2thZ2UgZGF0YQo=",
            keyPackageRef: "string",
            userID: userId
        )

        // When
        let receivedKeyPackages = test_itHandlesSuccess(
            status: 200,
            payload: transportData(for: Payload(keyPackages: [keyPackage]))
        )

        // Then
        XCTAssertEqual(receivedKeyPackages?.count, 1)
        XCTAssertEqual(receivedKeyPackages?.first, keyPackage)
    }

    func test_itHandlesEmptyKeyPackagesAsFailure() {
        test_itHandlesFailure(
            status: 200,
            payload: transportData(for: Payload(keyPackages: [])),
            expectedError: .emptyKeyPackages
        )
    }

    func test_itHandlesEmptyKeyPackagesAsSuccessIfSelfUser() {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        action = ClaimMLSKeyPackageAction(
            domain: selfUser.domain,
            userId: selfUser.remoteIdentifier,
            ciphersuite: ciphersuite
        )

        test_itHandlesSuccess(
            status: 200,
            payload: transportData(for: Payload(keyPackages: []))
        )

    }

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 400, error: .invalidSelfClientId),
            .failure(status: 404, error: .userOrDomainNotFound),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
