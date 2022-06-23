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

class ClaimMLSKeyPackageActionHandlerTests: ActionHandlerTestBase<ClaimMLSKeyPackageAction, ClaimMLSKeyPackageActionHandler> {

    private typealias Payload = ClaimMLSKeyPackageActionHandler.ResponsePayload

    let domain = "example.com"
    let userId = UUID()
    let excludedSelfCliendId = UUID().transportString()
    let clientId = UUID().transportString()

    override func setUp() {
        super.setUp()
        action = ClaimMLSKeyPackageAction(
            domain: domain,
            userId: userId
        )
    }

    // MARK: - Request generation

    func test_itGeneratesARequest() throws {
        try test_itGeneratesARequest(
            for: ClaimMLSKeyPackageAction(
                domain: domain,
                userId: userId,
                excludedSelfClientId: excludedSelfCliendId
            ),
            expectedPath: "/v1/mls/key-packages/claim/\(domain)/\(userId.transportString())",
            expectedPayload: ["skip_own": excludedSelfCliendId],
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

        // when the domain is missing
        APIVersion.domain = nil

        test_itDoesntGenerateARequest(
            action: ClaimMLSKeyPackageAction(domain: "", userId: userId, excludedSelfClientId: excludedSelfCliendId),
            apiVersion: .v1,
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

    func test_itHandlesFailures() {
        test_itHandlesFailures([
            .failure(status: 200, error: .malformedResponse),
            .failure(status: 400, error: .invalidSelfClientId),
            .failure(status: 404, error: .userOrDomainNotFound),
            .failure(status: 999, error: .unknown(status: 999))
        ])
    }
}
