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

final class UserClientsAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any UserClientsAPI>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            let builder = UserClientsAPIBuilder(apiService: apiService)
            return builder.makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
        super.tearDown()
    }

    // MARK: - Request generation

    func testGetSelfClients() async throws {
        var responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, "GetSelfClientsSuccessResponseV0"),
            count: APIVersion.allCasesUpTo(.v7).count
        )
        responses.append(
            contentsOf: Array(
                repeating: (.ok, "GetSelfClientsSuccessResponseV7"),
                count: APIVersion.v7.andNextVersions.count
            )
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions(apiService: apiService) { sut in
            _ = try await sut.getSelfClients()
        }
    }

    func testUpdateClient() async throws {
        let clientId = "000600d0-000b-9c1a-000d-a4130002c221"

        let scenarios: [(versions: [APIVersion], capabilities: [UserClientCapability]?)] = [
            (APIVersion.allCasesUpTo(.v8), [.legalholdConsent]),
            (APIVersion.v8.andNextVersions, [.legalholdConsent, .consumableNotifications])
        ]

        for scenario in scenarios {
            let responses = Array(
                repeating: MockAPIServiceProtocol.Response(.ok, nil),
                count: scenario.versions.count
            )
            let apiService = MockAPIServiceProtocol.withResponses(responses)

            try await apiSnapshotHelper.verifyRequest(for: scenario.versions, apiService: apiService) { sut in
                _ = try await sut.updateClient(
                    id: clientId,
                    clientUpdate: .init(capabilities: scenario.capabilities)
                )
            }
        }
    }

    func testRegisterClient() async throws {
        let scenarios: [(versions: [APIVersion], response: String?)] = [
            ([APIVersion.v5, .v6], "RegisterClientSuccessResponseV5"),
            (APIVersion.v7.andNextVersions, "RegisterClientSuccessResponseV7")
        ]

        for scenario in scenarios {
            let responses = Array(
                repeating: MockAPIServiceProtocol.Response(.created, scenario.response),
                count: scenario.versions.count
            )
            let apiService = MockAPIServiceProtocol.withResponses(responses)

            try await apiSnapshotHelper.verifyRequest(for: scenario.versions, apiService: apiService) { sut in
                _ = try await sut.registerClient(newClient: Scaffolding.newClient)
            }
        }
    }

    func testDeleteClient() async throws {
        let apiVersions = APIVersion.v5.andNextVersions
        let responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, nil),
            count: apiVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)
        try await apiSnapshotHelper.verifyRequest(for: apiVersions, apiService: apiService) { sut in
            _ = try await sut.deleteClient(
                id: "60f85e4b15ad3786",
                password: "strongPassword123"
            )
        }
    }

    func testDeleteClientWithoutPassword() async throws {
        let apiVersions = APIVersion.v5.andNextVersions
        let responses: [MockAPIServiceProtocol.Response] = Array(
            repeating: (.ok, nil),
            count: apiVersions.count
        )

        let apiService = MockAPIServiceProtocol.withResponses(responses)
        try await apiSnapshotHelper.verifyRequest(for: apiVersions, apiService: apiService) { sut in
            _ = try await sut.deleteClient(
                id: "60f85e4b15ad3786",
                password: nil
            )
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetSelfUserClients_SuccessResponse_200_V0_to_V6() async throws {
        try await withThrowingTaskGroup(of: [SelfUserClient].self) { taskGroup in
            let testedVersions = [APIVersion.v0, .v1, .v2, .v3, .v4, .v5, .v6]

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetSelfClientsSuccessResponseV0")
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.getSelfClients()
                }

                for try await value in taskGroup {
                    for item in value {
                        // Then
                        XCTAssertEqual(item, Scaffolding.userClient)
                    }
                }
            }
        }
    }

    func testGetUserClients_SuccessResponse_200_V0_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: [OtherUserClients].self) { taskGroup in
            let testedVersions = APIVersion.v0.andNextVersions

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetOtherUserClientsSuccessResponseV0")
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.getClients(for: [.mockID1, .mockID2, .mockID3])
                }

                for try await value in taskGroup {
                    // Then, ensures models are properly mapped
                    XCTAssert(value.contains(Scaffolding.otherUserClienst1))
                    XCTAssert(value.contains(Scaffolding.otherUserClienst2))
                    XCTAssert(value.contains(Scaffolding.otherUserClienst3))
                    XCTAssert(value.contains(Scaffolding.otherUserClienst4))
                }
            }
        }
    }

    func testRegisterClient_SuccessResponse_201_V5_to_V6() async throws {
        try await withThrowingTaskGroup(of: SelfUserClient.self) { taskGroup in
            let testedVersions = [APIVersion.v5, .v6]

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.created, "RegisterClientSuccessResponseV5")
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.registerClient(newClient: Scaffolding.newClient)
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(value, Scaffolding.registeredClient)
                }
            }
        }
    }

    func testRegisterClient_ThrowsEndpointUnavailable_V0_to_V4() async throws {
        let testedVersions = [APIVersion.v0, .v1, .v2, .v3, .v4]

        for version in testedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When/Then
            await XCTAssertThrowsErrorAsync(UserClientsAPIError.endpointUnavailable) {
                try await sut.registerClient(newClient: Scaffolding.newClient)
            }
        }
    }

    func testDeleteClient_SuccessResponse_200_V5_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            let testedVersions = APIVersion.v5.andNextVersions

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, nil)
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.deleteClient(
                        id: "60f85e4b15ad3786",
                        password: "strongPassword123"
                    )
                }

                for try await _ in taskGroup {
                    // Then - no assertion needed, just checking it doesn't throw
                }
            }
        }
    }

    func testDeleteClient_ThrowsEndpointUnavailable_V0_to_V4() async throws {
        let testedVersions = [APIVersion.v0, .v1, .v2, .v3, .v4]

        for version in testedVersions {
            // Given
            let apiService = MockAPIServiceProtocol()
            let sut = version.buildAPI(apiService: apiService)

            // When/Then
            await XCTAssertThrowsErrorAsync(UserClientsAPIError.endpointUnavailable) {
                try await sut.deleteClient(
                    id: "60f85e4b15ad3786",
                    password: "strongPassword123"
                )
            }
        }
    }

    // MARK: - V7

    func testGetSelfUserClients_SuccessResponse_200_V7_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: [SelfUserClient].self) { taskGroup in
            let testedVersions = APIVersion.v7.andNextVersions

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetSelfClientsSuccessResponseV7")
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.getSelfClients()
                }

                for try await value in taskGroup {
                    for item in value {
                        // Then
                        XCTAssertEqual(item, Scaffolding.userClient)
                    }
                }
            }
        }
    }

    func testRegisterClient_SuccessResponse_201_V7_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: SelfUserClient.self) { taskGroup in
            let testedVersions = APIVersion.v7.andNextVersions

            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.created, "RegisterClientSuccessResponseV7")
                ])

                let sut = version.buildAPI(apiService: apiService)

                taskGroup.addTask {
                    // When
                    try await sut.registerClient(newClient: Scaffolding.newClient)
                }

                for try await value in taskGroup {
                    // Then
                    XCTAssertEqual(value, Scaffolding.registeredClient)
                }
            }
        }
    }

    // MARK: -

    enum Scaffolding {
        static let userClient = SelfUserClient(
            id: "string",
            type: .temporary,
            activationDate: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            label: "string",
            model: "string",
            deviceClass: .phone,
            lastActiveDate: nil,
            mlsPublicKeys: .init(ed25519: "ZXhhbXBsZQo=", p256: nil, p384: nil, p521: nil),
            cookie: "string",
            capabilities: [.legalholdConsent]
        )

        static let newClient = NewClient(
            prekeys: [
                .init(
                    id: 0,
                    base64EncodedKey: "pQABARn//wKhAFggwO2Any+CjiGP8XFYrY67zHPvLgp+ysY5k7vci57aaLwDoQChAFggQU/vrXc9MrQxPNubQz4NI0uNtF6qdJ0J0mF9XB2f/GEEY="
                ),
                .init(
                    id: 1,
                    base64EncodedKey: "pQABARn//wKhAFgg0C2BN+Mxl7dLoDHNx7ZgUE7MR6hEqTmhoQrLmR5MQqYDoQChAFggJQvUqsCdqZ8o4s+OkSlRDPAf8DPQW25uG0+MvxWZxF4E="
                )
            ],
            lastkey: .init(
                id: 65_535,
                base64EncodedKey: "pQABARn//wKhAFgg3ULpZ5zKDp0p+b4SaV0eQa4YqqRVZkrsjn5EwgcbBdQDoQChAFggEHDNP6QHM4VD0JF0wFQlkc7AXQ/qQAR5kXmxFIuSnqYE="
            ),
            type: .permanent,
            capabilities: [.legalholdConsent],
            deviceClass: .phone,
            cookie: nil,
            label: "iPhone 12",
            model: "iPhone 12",
            password: nil,
            verificationCode: nil,
            mlsPublicKeys: .init(
                ed25519: "gRNvFYReriXbzsGu7z6OOr6FxITm/L6WhB8HUmcXG7E=",
                p256: nil,
                p384: nil,
                p521: nil
            )
        )

        static let registeredClient = SelfUserClient(
            id: "60f85e4b15ad3786",
            type: .permanent,
            activationDate: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            label: "iPhone 12",
            model: "iPhone 12",
            deviceClass: .phone,
            lastActiveDate: nil,
            mlsPublicKeys: .init(
                ed25519: "gRNvFYReriXbzsGu7z6OOr6FxITm/L6WhB8HUmcXG7E=",
                p256: nil,
                p384: nil,
                p521: nil
            ),
            cookie: "zbRsaJkNdE6OwZRvqPrhTKod5rIimeYRRWKHSMCvsGU=",
            capabilities: [.legalholdConsent]
        )

        static let otherUserClienst1 = OtherUserClients(
            domain: "domain1.example.com",
            userID: UUID(uuidString: "000600d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .desktop)]
        )

        static let otherUserClienst2 = OtherUserClients(
            domain: "domain2.example.com",
            userID: UUID(uuidString: "000700d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .phone)]
        )

        static let otherUserClienst3 = OtherUserClients(
            domain: "domain2.example.com",
            userID: UUID(uuidString: "000800d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .tablet)]
        )

        static let otherUserClienst4 = OtherUserClients(
            domain: "domain3.example.com",
            userID: UUID(uuidString: "000900d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold)]
        )

    }

}

private extension APIVersion {
    func buildAPI(apiService: any APIServiceProtocol) -> any UserClientsAPI {
        let builder = UserClientsAPIBuilder(apiService: apiService)
        return builder.makeAPI(for: self)
    }
}
