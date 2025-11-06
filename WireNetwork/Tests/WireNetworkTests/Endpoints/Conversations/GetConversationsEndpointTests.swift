//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import Testing
@testable import WireNetwork
@testable import WireNetworkSupport

struct GetConversationsEndpointTests {

    let apiService = MockAPIServiceProtocol()

    @Test(
        "Endpoint is unavailable for a given API version",
        arguments: APIVersion.up(to: .v5)
    )
    func endpointIsUnavailable(for apiVersion: APIVersion) async throws {
        // Given
        let sut = GetConversationsEndpoint(
            apiVersion: apiVersion,
            apiService: apiService
        )

        // Then
        await #expect(throws: RestAPIError.unsupportedAPIVersion(apiVersion)) {
            // When
            try await sut(for: [])
        }
    }

    @Test(
        "Gets conversations",
        arguments: [APIVersion.v5, .v6, .v7]
    )
    func getsConversations(for apiVersion: APIVersion) async throws {
        // Given
        let sut = GetConversationsEndpoint(
            apiVersion: apiVersion,
            apiService: apiService
        )

        let ids = [
            "99db9768-04e3-4b5d-9268-831b6a25c4ab",
            "f4a1296c-277a-4b73-ba02-5bd8b81b4ea5",
            "498f41b6-5341-4cc9-82e3-969d72675dd4"
        ].map {
            QualifiedID(
                id: UUID(uuidString: $0)!,
                domain: "example.com"
            )
        }

        apiService.mockResponse(
            code: .ok,
            resourceName: "GetConversationsV5Success",
            apiVersion: apiVersion,
            snapshotRequest: true,
            recordEnabled: false
        )

        // When
        let conversations = try await sut(for: ids)

        // Then
        #expect(conversations.found.count == 1)
        #expect(conversations.notFound.count == 1)
        #expect(conversations.failed.count == 1)
    }

}

private extension MockAPIServiceProtocol {

    func mockResponse(
        code: HTTPStatusCode,
        resourceName: String,
        apiVersion: APIVersion,
        snapshotRequest: Bool,
        recordEnabled: Bool = false,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line,
    ) {
        executeRequestRequiringAccessToken_MockMethod = { request, _ in
            try await HTTPRequestSnapshotHelper()
                .verifyRequestThrowing(
                    request: request,
                    resourceName: "v\(apiVersion.rawValue)",
                    record: recordEnabled,
                    file: file,
                    function: function,
                    line: line
                )
            return try request.mockResponse(
                statusCode: code,
                jsonResourceName: resourceName
            )
        }
    }
}

private extension APIVersion {

    static func up(
        to version: APIVersion,
        inclusive: Bool = false
    ) -> [APIVersion] {
        allCases.filter {
            if inclusive {
                $0 <= version
            } else {
                $0 < version
            }
        }
    }

    static func from(_ version: APIVersion) -> [APIVersion] {
        allCases.filter {
            $0 >= version
        }
    }

}
