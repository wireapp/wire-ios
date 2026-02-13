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

final class FeatureConfigsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any FeatureConfigsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = FeatureConfigsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetFeatureConfigs() async throws {
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetFeatureConfigsSuccessResponseV0"),
            (.ok, "GetFeatureConfigsSuccessResponseV1"),
            (.ok, "GetFeatureConfigsSuccessResponseV1"),
            (.ok, "GetFeatureConfigsSuccessResponseV1"),
            (.ok, "GetFeatureConfigsSuccessResponseV4"),
            (.ok, "GetFeatureConfigsSuccessResponseV4"),
            (.ok, "GetFeatureConfigsSuccessResponseV6"),
            (.ok, "GetFeatureConfigsSuccessResponseV6"),
            (.ok, "GetFeatureConfigsSuccessResponseV8"),
            (.ok, "GetFeatureConfigsSuccessResponseV8"),
            (.ok, "GetFeatureConfigsSuccessResponseV10"),
            (.ok, "GetFeatureConfigsSuccessResponseV11"),
            (.ok, "GetFeatureConfigsSuccessResponseV12"),
            (.ok, "GetFeatureConfigsSuccessResponseV12"),
            (.ok, "GetFeatureConfigsSuccessResponseV14"),
            (.ok, "GetFeatureConfigsSuccessResponseV14")
        ])

        try await apiSnapshotHelper.verifyRequestForAllAPIVersions(apiService: apiService) { sut in
            _ = try await sut.getFeatureConfigs()
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetFeatureConfigs_SuccessResponse_200_V0() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetFeatureConfigsSuccessResponseV0")
        ])

        // When
        try await apiSnapshotHelper.verifyRequest(for: [.v0], apiService: apiService) { sut in
            let result = try await sut.getFeatureConfigs()
            // Then
            XCTAssertEqual(
                result,
                Scaffolding.featureConfigsV0
            )
        }
    }

    // MARK: - V1 to V3

    func testGetFeatureConfigs_SuccessResponse_200_V1_to_V3_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV1"), count: 3)
        )

        let supportedVersions: [APIVersion] = [.v1, .v2, .v3]

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV1)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    func testGetFeatureConfigs_FailureResponse_No_Team() async throws {
        // Given

        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .notFound,
            label: "no-team"
        )

        let sut = FeatureConfigsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(FeatureConfigsAPIError.teamNotFound) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    func testGetFeatureConfigs_FailureResponse_No_Team_Member() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "no-team-member"
        )

        let sut = FeatureConfigsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(FeatureConfigsAPIError.userIsNotTeamMember) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    func testGetFeatureConfigs_FailureResponse_Insufficient_Permissions() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withError(
            statusCode: .forbidden,
            label: "operation-denied"
        )

        let sut = FeatureConfigsAPIV0(apiService: apiService)

        // Then
        await XCTAssertThrowsErrorAsync(FeatureConfigsAPIError.insufficientPermissions) {
            // When
            try await sut.getFeatureConfigs()
        }
    }

    // MARK: - V4 & V5

    func testGetFeatureConfigs_SuccessResponse_200_V4_To_V5_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV4"), count: 2)
        )

        let supportedVersions: [APIVersion] = [.v4, .v5]

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV4)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V6 and next versions

    func testGetFeatureConfigs_SuccessResponse_200_V6_And_Next_Versions_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV6"), count: 2)
        )

        let supportedVersions = [APIVersion.v6, APIVersion.v7]

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV6)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V8

    func testGetFeatureConfigs_SuccessResponse_200_V8_V9_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV8"), count: 2)
        )

        let supportedVersions = [APIVersion.v8, .v9]

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV8)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V10

    func testGetFeatureConfigs_SuccessResponse_200_V10_And_Next_Versions_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetFeatureConfigsSuccessResponseV10")
        ])

        let supportedVersions = [APIVersion.v10] // .andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV10)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V11

    func testGetFeatureConfigs_SuccessResponse_200_V11_And_Next_Versions_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses([
            (.ok, "GetFeatureConfigsSuccessResponseV11")
        ])

        let supportedVersions = [APIVersion.v11] // .andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV11)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V12

    func testGetFeatureConfigs_SuccessResponse_200_V12_And_Next_Versions_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV12"), count: 2)
        )

        let supportedVersions = [APIVersion.v12, APIVersion.v13]

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()

            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV12)
            XCTAssertEqual(resultSet, expectedSet)
        }
    }

    // MARK: - V14

    func testGetFeatureConfigs_SuccessResponse_200_V14_And_Next_Versions_Then_Verify_Requests() async throws {
        // Given
        let apiService = MockAPIServiceProtocol.withResponses(
            Array(repeating: (.ok, "GetFeatureConfigsSuccessResponseV14"), count: 2)
        )

        let supportedVersions = APIVersion.v14.andNextVersions

        // Then
        try await apiSnapshotHelper.verifyRequest(for: supportedVersions, apiService: apiService) { sut in
            // When
            let result = try await sut.getFeatureConfigs()
            // Then
            let resultSet = Set(result)
            let expectedSet = Set(Scaffolding.featureConfigsV14)
            XCTAssertEqual(resultSet, expectedSet)
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
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: false
                )
            ),
            .conversationGuestLinks(
                .init(
                    status: .enabled
                )
            ),
            .digitalSignature(
                .init(
                    status: .enabled
                )
            ),
            .fileSharing(
                .init(
                    status: .enabled
                )
            ),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            )
        ]

        static let featureConfigsV1: [FeatureConfig] = [
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: false
                )
            ),
            .conversationGuestLinks(
                .init(
                    status: .enabled
                )
            ),
            .digitalSignature(
                .init(
                    status: .enabled
                )
            ),
            .fileSharing(
                .init(
                    status: .enabled
                )
            ),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(
                .init(
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
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: false
                )
            ),
            .conversationGuestLinks(.init(status: .enabled)),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(
                .init(
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
            .mlsMigration(
                .init(
                    status: .enabled,
                    startTime: dateV4(from: "2021-05-12T10:52:02.671Z"),
                    finaliseRegardlessAfter: dateV4(from: "2021-05-12T10:52:02.671Z")
                )
            ),
            .endToEndIdentity(
                .init(
                    status: .enabled,
                    acmeDiscoveryURL: "https://example.com",
                    verificationExpiration: 9_223_372_036_854_776_000,
                    crlProxy: nil,
                    useProxyOnMobile: false
                )
            )
        ]

        static let featureConfigsV6: [FeatureConfig] = [
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: true
                )
            ),
            .conversationGuestLinks(
                .init(status: .enabled)
            ),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(
                .init(
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
            .mlsMigration(
                .init(
                    status: .enabled,
                    startTime: dateV6(from: "2021-05-12T10:52:02Z"),
                    finaliseRegardlessAfter: dateV6(from: "2021-05-12T10:52:02Z")
                )
            ),
            .endToEndIdentity(
                .init(
                    status: .enabled,
                    acmeDiscoveryURL: "https://example.com",
                    verificationExpiration: 9_223_372_036_854_776_000,
                    crlProxy: "https://example.com",
                    useProxyOnMobile: true
                )
            )
        ]

        static let featureConfigsV8: [FeatureConfig] = [
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: true
                )
            ),
            .conversationGuestLinks(
                .init(status: .enabled)
            ),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(
                .init(
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
            .mlsMigration(
                .init(
                    status: .enabled,
                    startTime: dateV6(from: "2021-05-12T10:52:02Z"),
                    finaliseRegardlessAfter: dateV6(from: "2021-05-12T10:52:02Z")
                )
            ),
            .endToEndIdentity(
                .init(
                    status: .enabled,
                    acmeDiscoveryURL: "https://example.com",
                    verificationExpiration: 9_223_372_036_854_776_000,
                    crlProxy: "https://example.com",
                    useProxyOnMobile: true
                )
            ),
            .channels(
                .init(
                    status: .enabled,
                    allowedToCreateChannels: .everyone,
                    allowedToOpenChannels: .admins
                )
            ),
            .cells(.init(status: .enabled))
        ]

        static let featureConfigsV10: [FeatureConfig] = [
            .appLock(
                .init(
                    status: .enabled,
                    isMandatory: true,
                    inactivityTimeoutInSeconds: 2_147_483_647
                )
            ),
            .classifiedDomains(
                .init(
                    status: .enabled,
                    domains: ["example.com"]
                )
            ),
            .conferenceCalling(
                .init(
                    status: .enabled,
                    useSFTForOneToOneCalls: true
                )
            ),
            .conversationGuestLinks(
                .init(status: .enabled)
            ),
            .digitalSignature(.init(status: .enabled)),
            .fileSharing(.init(status: .enabled)),
            .selfDeletingMessages(
                .init(
                    status: .enabled,
                    enforcedTimeoutSeconds: 2_147_483_647
                )
            ),
            .mls(
                .init(
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
            .mlsMigration(
                .init(
                    status: .enabled,
                    startTime: dateV6(from: "2021-05-12T10:52:02Z"),
                    finaliseRegardlessAfter: dateV6(from: "2021-05-12T10:52:02Z")
                )
            ),
            .endToEndIdentity(
                .init(
                    status: .enabled,
                    acmeDiscoveryURL: "https://example.com",
                    verificationExpiration: 9_223_372_036_854_776_000,
                    crlProxy: "https://example.com",
                    useProxyOnMobile: true
                )
            ),
            .channels(
                .init(
                    status: .enabled,
                    allowedToCreateChannels: .everyone,
                    allowedToOpenChannels: .admins
                )
            ),
            .allowedGlobalOperations(
                .init(
                    status: .enabled,
                    resetMLSConversations: true
                )
            ),
            .cells(.init(status: .enabled))
        ]

        static let featureConfigsV11: [FeatureConfig] = featureConfigsV10 + [
            .apps(.init(status: .enabled)),
            .consumableNotifications(.init(status: .enabled)),
            .cells(.init(status: .enabled))
        ]

        static let featureConfigsV12: [FeatureConfig] = featureConfigsV11 + [
            .assetAuditLog(.init(status: .enabled)),
            .simplifiedUserConnectionRequestQRCode(.init(status: .disabled))
        ]

        static let featureConfigsV14: [FeatureConfig] = featureConfigsV12 + [
            .assetAuditLog(.init(status: .enabled)),
            .cellsInternal(.init(status: .enabled, backendURL: URL(string: "https://example.com")!))
        ]

    }

}
