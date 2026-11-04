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

final class ContactStatusAPITests: XCTestCase {

    func testGetUsers_ContactStatusQueryIsOptInFromV17() async throws {
        for version in APIVersion.allCases {
            for includeContactStatus in [false, true] {
                let resource = version < .v4 ? "GetUsersSuccessResponseV0" : "GetUsersSuccessResponseV4"
                let apiService = MockAPIServiceProtocol.withResponses([(.ok, resource)])
                let sut = UsersAPIBuilder(apiService: apiService).makeAPI(for: version)

                _ = try await sut.getUsers(userIDs: [.mockID1], includeContactStatus: includeContactStatus)

                let invocation = try XCTUnwrap(apiService.executeRequestRequiringAccessToken_Invocations.first)
                let url = try XCTUnwrap(invocation.request.url)
                let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
                let expectedQueryItems: [URLQueryItem]? = version >= .v17 && includeContactStatus
                    ? [URLQueryItem(name: "include-contact-status", value: "true")]
                    : nil
                XCTAssertEqual(
                    components.queryItems,
                    expectedQueryItems,
                    "API \(version), opt-in \(includeContactStatus)"
                )
            }
        }
    }

    func testGetUser_V17AndAbove_DecodesContactStatus() async throws {
        for version in APIVersion.v17.andNextVersions {
            for (json, expectedStatus) in Scaffolding.contactStatuses {
                let userJSON = try makeUserJSON(contactStatus: json)
                let apiService = try makeAPIService(response: userJSON)
                let sut = UsersAPIBuilder(apiService: apiService).makeAPI(for: version)

                let user = try await sut.getUser(for: .mockID1)

                XCTAssertEqual(user.contactStatus, expectedStatus, "API \(version), status \(String(describing: json))")
                XCTAssertEqual(user.name, "name")
                XCTAssertEqual(user.app, AppInfo(category: "cat", description: "desc"))
                XCTAssertEqual(user.supportedProtocols, [.proteus])
            }
        }
    }

    func testGetUsers_V17AndAbove_DecodesContactStatuses() async throws {
        let users = try Scaffolding.contactStatuses.map { try makeUserJSON(contactStatus: $0.json) }
        let failed: [[String: Any]] = [["id": UserID.mockID1.id.uuidString, "domain": UserID.mockID1.domain]]

        for version in APIVersion.v17.andNextVersions {
            let apiService = try makeAPIService(response: ["found": users, "failed": failed])
            let sut = UsersAPIBuilder(apiService: apiService).makeAPI(for: version)

            let result = try await sut.getUsers(userIDs: [.mockID1], includeContactStatus: true)

            XCTAssertEqual(result.found.map(\.contactStatus), Scaffolding.contactStatuses.map(\.status))
            XCTAssertEqual(result.failed, [.mockID1])
        }
    }

    func testGetApps_V17AndAbove_DecodesContactStatuses() async throws {
        let users = try Scaffolding.contactStatuses.map { try makeUserJSON(contactStatus: $0.json) }

        for version in APIVersion.v17.andNextVersions {
            let apiService = try makeAPIService(response: users)
            let sut = TeamsAPIBuilder(apiService: apiService).makeAPI(for: version)

            let apps = try await sut.getApps(for: .mockID1)

            XCTAssertEqual(apps.map(\.contactStatus), Scaffolding.contactStatuses.map(\.status))
        }
    }

    func testGetUser_V16_IgnoresContactStatus() async throws {
        let apiService = try makeAPIService(response: makeUserJSON(contactStatus: #"{"state":"contactable"}"#))
        let sut = UsersAPIBuilder(apiService: apiService).makeAPI(for: .v16)

        let user = try await sut.getUser(for: .mockID1)

        XCTAssertNil(user.contactStatus)
    }

    func testGetUser_V17AndAbove_MapsNotFoundError() async throws {
        for version in APIVersion.v17.andNextVersions {
            let apiService = MockAPIServiceProtocol.withError(statusCode: .notFound, label: "not-found")
            let sut = UsersAPIBuilder(apiService: apiService).makeAPI(for: version)

            await XCTAssertThrowsErrorAsync(UsersAPIError.userNotFound) {
                try await sut.getUser(for: .mockID1)
            }
        }
    }

    func testUserResponseV17_ContactStatusRequiresState() throws {
        let response = try makeUserJSON(contactStatus: "{}")
        let data = try JSONSerialization.data(withJSONObject: response)

        XCTAssertThrowsError(try JSONDecoder().decode(UserResponseV17.self, from: data)) { error in
            guard case let DecodingError.keyNotFound(key, _) = error else {
                return XCTFail("Expected missing state, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "state")
        }
    }

    // MARK: - Helpers

    private func makeUserJSON(contactStatus: String?) throws -> [String: Any] {
        let resource = try MockJSONPayloadResource(name: "GetUserSuccessResponseV15")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: resource.jsonData) as? [String: Any])
        if let contactStatus {
            json["contact_status"] = try JSONSerialization.jsonObject(
                with: Data(contactStatus.utf8),
                options: .fragmentsAllowed
            )
        }
        return json
    }

    private func makeAPIService(response: Any) throws -> MockAPIServiceProtocol {
        let data = try JSONSerialization.data(withJSONObject: response)
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            let (_, response) = try request.mockResponse(statusCode: .ok)
            return (data, response)
        }
        return apiService
    }

    private enum Scaffolding {

        static let contactStatuses: [(json: String?, status: ContactStatus?)] = [
            (#"{"state":"contactable"}"#, .contactable),
            (#"{"state":"non-contactable"}"#, .nonContactable),
            (nil, nil),
            ("null", nil)
        ]

    }

}
