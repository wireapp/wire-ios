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

import XCTest
@testable import WireAPISupport
@testable import WireAPI

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
        try await apiSnapshotHelper.verifyRequestForAllAPIVersions { sut in
            _ = try await sut.getSelfClients()
        }
    }

    // MARK: - Response handling

    // MARK: - V0

    func testGetSelfUserClients_SuccessResponse_200_V0_And_Next_Versions() async throws {
        try await withThrowingTaskGroup(of: [UserClient].self) { taskGroup in
            let testedVersions = APIVersion.v0.andNextVersions
            
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
        try await withThrowingTaskGroup(of: [UserClients].self) { taskGroup in
            let testedVersions = APIVersion.v0.andNextVersions
            
            for version in testedVersions {
                // Given
                let apiService = MockAPIServiceProtocol.withResponses([
                    (.ok, "GetClientsSuccessResponseV0")
                ])
                
                let sut = version.buildAPI(apiService: apiService)
                
                taskGroup.addTask {
                    // When
                    try await sut.getClients(for: [.mockID1, .mockID2, .mockID3])
                }

                for try await value in taskGroup {
                    // Then, ensures models are properly mapped
                    XCTAssert(value.contains(Scaffolding.userClient1))
                    XCTAssert(value.contains(Scaffolding.userClient2))
                    XCTAssert(value.contains(Scaffolding.userClient3))
                    XCTAssert(value.contains(Scaffolding.userClient4))
                }
            }
        }
    }

    enum Scaffolding {
        static let userClient = UserClient(
            id: "string",
            type: .temporary,
            activationDate: ISO8601DateFormatter.fractionalInternetDateTime.date(from: "2021-05-12T10:52:02.671Z")!,
            label: "string",
            model: "string",
            deviceClass: .phone,
            lastActiveDate: nil,
            mlsPublicKeys: .init(ed25519: "ZXhhbXBsZQo=", ed448: nil, p256: nil, p384: nil, p512: nil),
            cookie: "string",
            capabilities: [.legalholdConsent]
        )

        static let userClient1 = UserClients(
            domain: "domain1.example.com",
            userID: UUID(uuidString: "000600d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .desktop)]
        )

        static let userClient2 = UserClients(
            domain: "domain2.example.com",
            userID: UUID(uuidString: "000700d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .phone)]
        )

        static let userClient3 = UserClients(
            domain: "domain2.example.com",
            userID: UUID(uuidString: "000800d0-000b-9c1a-000d-a4130002c221")!,
            clients: [.init(id: "d0", deviceClass: .legalhold), .init(id: "d0", deviceClass: .tablet)]
        )

        static let userClient4 = UserClients(
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
