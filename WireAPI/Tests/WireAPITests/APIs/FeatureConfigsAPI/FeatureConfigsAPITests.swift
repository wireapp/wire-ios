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

import SnapshotTesting
import XCTest

@testable import WireAPI

final class FeatureConfigsAPITests: XCTestCase {

    private var apiSnapshotHelper: APISnapshotHelper<any FeatureConfigsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APISnapshotHelper { httpClient, apiVersion in
            let builder = FeatureConfigsAPIBuilder(httpClient: httpClient)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetFeatureConfigs() async throws {
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getFeatureConfigs()
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetFeatureConfigs_SuccessResponse_200_V0() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetFeatureConfigsSuccessResponseV0"
        )

        let sut = APIVersion.v0.buildAPI(client: httpClient)

        // When
        let result = try await sut.getFeatureConfigs()

        // Then
        XCTAssertEqual(
            result,
            Scaffolding.featureConfigsV0
        )
    }

    // MARK: - V1 to V3

    func testGetFeatureConfigs_SuccessResponse_200_V1_to_V3() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetFeatureConfigsSuccessResponseV1"
        )

        let supportedVersions: [APIVersion] = [.v1, .v2, .v3]

        let suts = supportedVersions.map { $0.buildAPI(client: httpClient) }

        try await withThrowingTaskGroup(of: [FeatureConfig].self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // When
                    try await sut.getFeatureConfigs()
                }

                for try await result in taskGroup {
                    // Then
                    XCTAssertEqual(
                        result,
                        Scaffolding.featureConfigsV1
                    )
                }
            }
        }
    }

    func testGetFeatureConfigs_FailureResponse_No_Team() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .notFound, errorLabel: "no-team")
        let sut = FeatureConfigsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(FeatureConfigsAPIError.teamNotFound) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    func testGetFeatureConfigs_FailureResponse_No_Team_Member() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .forbidden, errorLabel: "no-team-member")
        let sut = FeatureConfigsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(FeatureConfigsAPIError.userIsNotTeamMember) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    func testGetFeatureConfigs_FailureResponse_Insufficient_Permissions() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .forbidden, errorLabel: "operation-denied")
        let sut = FeatureConfigsAPIV0(httpClient: httpClient)

        // Then
        await XCTAssertThrowsError(FeatureConfigsAPIError.insufficientPermissions) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    // MARK: - V4 & V5

    func testGetFeatureConfigs_SuccessResponse_200_V4_TO_V5() async throws {
        // Given
        let httpClient = try HTTPClientMock(code: .ok, payloadResourceName: "GetFeatureConfigsSuccessResponseV4")

        let supportedVersions: [APIVersion] = [.v4, .v5]

        let suts = supportedVersions.map { $0.buildAPI(client: httpClient) }

        try await withThrowingTaskGroup(of: [FeatureConfig].self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // When
                    try await sut.getFeatureConfigs()
                }

                for try await result in taskGroup {
                    // Then
                    XCTAssertEqual(
                        result,
                        Scaffolding.featureConfigsV4
                    )
                }
            }
        }
    }

    // MARK: - V6 and next versions

    func testGetFeatureConfigs_SuccessResponse_200_V6_And_Next_Versions() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: .ok,
            payloadResourceName: "GetFeatureConfigsSuccessResponseV6"
        )

        let supportedVersions = APIVersion.v6.andNextVersions

        let suts = supportedVersions.map { $0.buildAPI(client: httpClient) }

        try await withThrowingTaskGroup(of: [FeatureConfig].self) { taskGroup in
            for sut in suts {
                taskGroup.addTask {
                    // When
                    try await sut.getFeatureConfigs()
                }

                for try await result in taskGroup {
                    // Then
                    XCTAssertEqual(
                        result,
                        Scaffolding.featureConfigsV6
                    )
                }
            }
        }
    }

}

extension FeatureConfigsAPITests {

    enum Scaffolding {

        static func dateV4(from string: String) -> Date {
            ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
        }

        static func dateV6(from string: String) -> Date {
            ISO8601DateFormatter.internetDateTime.date(from: string)!
        }

        static let featureConfigsV0: [FeatureConfig] = [
            .appLock(.init(
                status: .enabled,
                isMandatory: true,
                inactivityTimeoutInSeconds: 2_147_483_647
            )
            ),
            .classifiedDomains(.init(
                status: .enabled,
                domains: ["example.com"]
            )
            ),
            .conferenceCalling(.init(
                status: .enabled,
                useSFTForOneToOneCalls: false
            )
            ),
            .conversationGuestLinks(.init(
                status: .enabled)
            ),
            .digitalSignature(.init(
                status: .enabled)
            ),
            .fileSharing(.init(
                status: .enabled)
            ),
            .selfDeletingMessages(.init(
                status: .enabled,
                enforcedTimeoutSeconds: 2_147_483_647
            )
            )
        ]

        static let featureConfigsV1: [FeatureConfig] = [
            .appLock(.init(
                status: .enabled,
                isMandatory: true,
                inactivityTimeoutInSeconds: 2_147_483_647
            )
            ),
            .classifiedDomains(.init(
                status: .enabled,
                domains: ["example.com"]
            )
            ),
            .conferenceCalling(.init(
                status: .enabled,
                useSFTForOneToOneCalls: false
            )
            ),
            .conversationGuestLinks(.init(
                status: .enabled)
            ),
            .digitalSignature(.init(
                status: .enabled)
            ),
            .fileSharing(.init(
                status: .enabled)
            ),
            .selfDeletingMessages(.init(
                status: .enabled,
                enforcedTimeoutSeconds: 2_147_483_647
            )
            ),
            .mls(.init(
                status: .enabled,
                protocolToggleUsers: [UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!],
                defaultProtocol: .proteus,
                allowedCipherSuites: [
                    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                    .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                    .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
                ],
                defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                supportedProtocols: [.proteus]
            )
            )
        ]

        static let featureConfigsV4: [FeatureConfig] = [
            .appLock(.init(
                status: .enabled,
                isMandatory: true,
                inactivityTimeoutInSeconds: 2_147_483_647
            )
            ),
            .classifiedDomains(.init(
                status: .enabled,
                domains: ["example.com"]
            )
            ),
            .conferenceCalling(.init(
                status: .enabled,
                useSFTForOneToOneCalls: false
            )
            ),
            .conversationGuestLinks(.init(status: .enabled)),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(.init(
                status: .enabled,
                enforcedTimeoutSeconds: 2_147_483_647
            )
            ),
            .mls(.init(
                status: .enabled,
                protocolToggleUsers: [UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!],
                defaultProtocol: .proteus,
                allowedCipherSuites: [
                    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                    .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                    .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
                ],
                defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                supportedProtocols: [.proteus]
            )
            ),
            .mlsMigration(.init(
                status: .enabled,
                startTime: dateV4(from: "2021-05-12T10:52:02.671Z"),
                finaliseRegardlessAfter: dateV4(from: "2021-05-12T10:52:02.671Z")
            )
            ),
            .endToEndIdentity(.init(
                status: .enabled,
                acmeDiscoveryURL: "https://example.com",
                verificationExpiration: 9_223_372_036_854_776_000,
                crlProxy: nil,
                useProxyOnMobile: false
            )
            )
        ]

        static let featureConfigsV6: [FeatureConfig] = [
            .appLock(.init(
                status: .enabled,
                isMandatory: true,
                inactivityTimeoutInSeconds: 2_147_483_647
            )
            ),
            .classifiedDomains(.init(
                status: .enabled,
                domains: ["example.com"]
            )
            ),
            .conferenceCalling(
                .init(status: .enabled,
                      useSFTForOneToOneCalls: true)
            ),
            .conversationGuestLinks(.init(status: .enabled)
            ),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(.init(
                status: .enabled,
                enforcedTimeoutSeconds: 2_147_483_647
            )
            ),
            .mls(.init(
                status: .enabled,
                protocolToggleUsers: [UUID(uuidString: "99db9768-04e3-4b5d-9268-831b6a25c4ab")!],
                defaultProtocol: .proteus,
                allowedCipherSuites: [
                    .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519,
                    .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                    .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519
                ],
                defaultCipherSuite: .MLS_128_DHKEMP256_AES128GCM_SHA256_P256,
                supportedProtocols: [.proteus]
            )
            ),
            .mlsMigration(.init(
                status: .enabled,
                startTime: dateV6(from: "2021-05-12T10:52:02Z"),
                finaliseRegardlessAfter: dateV6(from: "2021-05-12T10:52:02Z")
            )
            ),
            .endToEndIdentity(.init(
                status: .enabled,
                acmeDiscoveryURL: "https://example.com",
                verificationExpiration: 9_223_372_036_854_776_000,
                crlProxy: "https://example.com",
                useProxyOnMobile: true
            )
            )
        ]
    }

}

private extension APIVersion {

    func buildAPI(client: any HTTPClient) -> any FeatureConfigsAPI {
        let builder = FeatureConfigsAPIBuilder(httpClient: client)
        return builder.makeAPI(for: self)
    }

}
