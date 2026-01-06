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

@testable import WireNetwork
@testable import WireNetworkSupport

final class MLSAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any MLSAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = MLSAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Get backend MLS public keys

    func testGetBackendMLSPublicKeysRequest() async throws {
        // Given
        let apiVersions = APIVersion.v5.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.getBackendMLSPublicKeys()
        }
    }

    func testGetBackendMLSPublicKeys_SuccessResponse_200_V5_And_Next_Versions() async throws {
        // Given
        try await withThrowingTaskGroup(of: BackendMLSPublicKeys.self) { taskGroup in
            let testedVersions = APIVersion.v5.andNextVersions

            for version in testedVersions {
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetBackendMLSPublicKeysSuccessResponse1")
                ])
                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.getBackendMLSPublicKeys()
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(
                        value,
                        BackendMLSPublicKeys(
                            removal: .init(
                                ed25519: "YVAl3Nsu27aNpNbYlPB6fi",
                                p256: "BM036midcNiOMgny9m7N",
                                p384: "BPSlomkR8K4BcFLGTDOJx",
                                p521: "BAC3OmJi7rAPFAIXjU"
                            )
                        )
                    )
                }
            }
        }
    }

    func testGetBackendMLSPublicKeys_givenV5AndErrorResponse() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .badRequest,
            label: "mls-not-enabled"
        )

        let api = MLSAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(MLSAPIError.mlsNotEnabled) {
            // When
            try await api.getBackendMLSPublicKeys()
        }
    }

    // MARK: - Send commit bundle

    func testPostCommitBundleRequest() async throws {
        // Given
        let apiVersions = APIVersion.v5.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            // When
            _ = try await sut.postCommitBundle(Scaffolding.commitBundle)
        }
    }

    func testPostCommitBundle_SuccessResponse_201_V5_And_Next_Versions() async throws {
        // Given
        try await withThrowingTaskGroup(of: [UpdateEvent].self) { taskGroup in
            let testedVersions = APIVersion.v5.andNextVersions

            for version in testedVersions {
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.created, "PostCommitBundleSuccessResponse1")
                ])
                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.postCommitBundle(Scaffolding.commitBundle)
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(value, [], "should get 201 for APIVersion  \(version)")
                }
            }
        }
    }

    func testPostCommitBundle_SuccessResponseWithEvents_201_V5_And_Next_Versions() async throws {
        // Given
        try await withThrowingTaskGroup(of: [UpdateEvent].self) { taskGroup in
            let testedVersions = APIVersion.v5.andNextVersions

            for version in testedVersions {
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.created, "PostCommitBundleSuccessResponse2")
                ])
                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.postCommitBundle(Scaffolding.commitBundle)
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(value, Scaffolding.updateEvents, "should get 201 for APIVersion  \(version)")
                }
            }
        }
    }

    func testPostCommitBundle_givenV5AndErrorResponse() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .conflict,
            label: "mls-stale-message"
        )

        let api = MLSAPIV5(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(MLSAPIError.mlsStaleMessage) {
            // When
            try await api.postCommitBundle(Scaffolding.commitBundle)
        }
    }

    func testPostCommitBundle_givenv13AndErrorResponse() async throws {
        // Given
        struct Payload: Encodable {
            let code = 409
            let label = "mls-group-out-of-sync"
            let message = ""
            let missing_users: Set<QualifiedIDV0>
        }
        let missingUsers = Set([
            QualifiedID(id: UUID(), domain: "example.com"),
            QualifiedID(id: UUID(), domain: "example.com")
        ])
        let payload = Payload(missing_users: Set(missingUsers.map {
            $0.toNetworkModel()
        }))
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .conflict,
            payload: payload
        )
        let api = MLSAPIV13(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(MLSAPIError.groupOutOfSync(missingUsers: missingUsers)) {
            // When
            try await api.postCommitBundle(Scaffolding.commitBundle)
        }
    }

    // MARK: - Reset MLS conversation

    func testResetMLSConversation_SuccessResponse_V9() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, nil)
        ])
        let api = MLSAPIV9(apiService: apiService)

        // Then
        // When
        try await api.resetMLSConversation(epoch: Scaffolding.epoch, groupID: Scaffolding.groupID)
    }

}

private extension APIVersion {

    func buildAPI(apiService: any APIServiceProtocol) -> any MLSAPI {
        let builder = MLSAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }

}

// MARK: Helpers

private enum Scaffolding {

    static let epoch: UInt64 = .random(in: 1 ... 1000)
    static let groupID: String = "123456789"

    static let commitBundle = CommitBundle(
        welcome: nil,
        commit: Data("commit".utf8),
        groupInfo: Data("groupinfo".utf8)
    )

    static let updateEvents = [
        UpdateEvent.unknown(eventType: "some event")
    ]

}
