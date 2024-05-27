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

@testable import WireAPI

final class ConversationsAPITests: XCTestCase {

    private var snapshotHelper: RequestSnapshotHelper<ConversationsAPIBuilder>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
    }

    override func tearDown() {
        snapshotHelper = nil
    }

    // MARK: - Tests

    func testGetConversationIdentifiers() async throws {
        try await snapshotHelper.verifyRequestForAllAPIVersions { sut in
            let pager = try await sut.getConversationIdentifiers()
            for try await _ in pager {
                // this triggers fetching the data
            }
        }
    }

    func testGetConversationIdentifiers_givenV1AndSuccessResponse200() async throws {
        // Given
        let httpClient = try HTTPClientMock(
            code: 200,
            payloadResourceName: "testGetConversationIdentifiers_givenV1AndSuccessResponse200"
        )

        let api = ConversationsAPIV1(httpClient: httpClient)

        // When
        let pager = try await api.getConversationIdentifiers()
        var iterator = pager.makeAsyncIterator()
        let result = try await iterator.next()

        // Then
        XCTAssertEqual(result?.first, [
            .init(
                uuid: try XCTUnwrap(UUID(uuidString: "14c3f0ff-1a46-4e66-8845-ae084f09c483")),
                domain: "staging.zinfra.io"
            )
        ])
    }
}
