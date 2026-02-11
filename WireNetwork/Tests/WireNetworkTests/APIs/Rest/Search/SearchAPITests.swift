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

final class SearchAPITests: XCTestCase {

    private var apiSnapshotHelper: APIServiceSnapshotHelper<any SearchAPI>!

    // MARK: - Setup

    override func setUp() {
        apiSnapshotHelper = APIServiceSnapshotHelper { apiService, apiVersion in
            SearchAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion)
        }
    }

    override func tearDown() {
        apiSnapshotHelper = nil
    }

    // MARK: - Request generation

    /// Ensure certain characters are escaped:
    /// - Ampersand: `%26`
    /// - Plus: `%2B` (this doesn't seem to be testable with the snapshot library)
    /// - Equals sign: `%3D`
    func testEncodingCharacters() async throws {
        let apiVersions = APIVersion.v0.andNextVersions
        try await apiSnapshotHelper.verifyRequest(for: apiVersions) { sut in
            _ = try await sut.searchContacts(query: "$&+,/:;=?@ Steve O'Hara & Söhne", domain: "wire.com", type: .regular)
        }
    }

    // MARK: - Response handling

    // MARK: - V1

    func testSearchContacts_SuccessResponse_200_V1ToV14_Then_Verify_Request() async throws {

        let v1To14 = Set(APIVersion.allCasesUpTo(.v15)).subtracting([.v0])
        for apiVersion in v1To14 {

            // Given
            let apiService = MockAPIServiceProtocol.withResponses([
                (.ok, "GetSearchContactsSuccessResponseV1")
            ])

            // When
            try await apiSnapshotHelper.verifyRequest(for: [apiVersion], apiService: apiService) { sut in
                let contacts = try await sut.searchContacts(query: "lorem ipsum", domain: "", type: .app).documents

                // Then
                XCTAssertEqual(
                    contacts,
                    [
                        .init(
                            id: UUID(uuidString: "3e90c8f5-80d7-4e42-b188-8679a58b7a8f"),
                            qualifiedID: .init(
                                id: UUID(uuidString: "3e90c8f5-80d7-4e42-b188-8679a58b7a8f")!,
                                domain: "staging.zinfra.io"
                            ),
                            name: "Poll App",
                            handle: nil,
                            team: UUID(uuidString: "169685e3-c5e5-45a3-9f3c-1485bb9dcba9"),
                            accentID: 0,
                            type: .regular // v1 has no type field, `regular` is assumed
                        ),
                        .init(
                            id: UUID(uuidString: "aca5dddd-59a0-411e-803d-df64d4c93c44"),
                            qualifiedID: .init(
                                id: UUID(uuidString: "aca5dddd-59a0-411e-803d-df64d4c93c44")!,
                                domain: "staging.zinfra.io"
                            ),
                            name: "Lorem Ipsum",
                            handle: "loremipsum",
                            team: nil,
                            accentID: 5,
                            type: .regular // v1 has no type field, `regular` is assumed
                        )
                    ],
                    "failed for version \(apiVersion)"
                )
            }
        }
    }

    // MARK: - V15

    func testSearchContacts_SuccessResponse_200_V15AndAbove_Then_Verify_Request() async throws {

        for apiVersion in APIVersion.v15.andNextVersions {

            // Given
            let apiService = MockAPIServiceProtocol.withResponses([
                (.ok, "GetSearchContactsSuccessResponseV15")
            ])

            // When
            try await apiSnapshotHelper.verifyRequest(for: [apiVersion], apiService: apiService) { sut in
                let contacts = try await sut.searchContacts(query: "lorem ipsum", domain: "", type: .app).documents

                // Then
                XCTAssertEqual(
                    contacts,
                    [
                        .init(
                            id: UUID(uuidString: "3e90c8f5-80d7-4e42-b188-8679a58b7a8f"),
                            qualifiedID: .init(
                                id: UUID(uuidString: "3e90c8f5-80d7-4e42-b188-8679a58b7a8f")!,
                                domain: "staging.zinfra.io"
                            ),
                            name: "Poll App",
                            handle: nil,
                            team: UUID(uuidString: "169685e3-c5e5-45a3-9f3c-1485bb9dcba9"),
                            accentID: 0,
                            type: .app // v15 knows the `type` field
                        ),
                        .init(
                            id: UUID(uuidString: "aca5dddd-59a0-411e-803d-df64d4c93c44"),
                            qualifiedID: .init(
                                id: UUID(uuidString: "aca5dddd-59a0-411e-803d-df64d4c93c44")!,
                                domain: "staging.zinfra.io"
                            ),
                            name: "Lorem Ipsum",
                            handle: "loremipsum",
                            team: nil,
                            accentID: 5,
                            type: .regular
                        )
                    ],
                    "failed for version \(apiVersion)"
                )
            }
        }
    }

}
