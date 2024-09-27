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

import Foundation
@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class SearchDirectoryTests: DatabaseTest {
    private var mockCache: SearchUsersCache!
    private var mockTransport: MockTransportSession!

    override func setUp() {
        super.setUp()

        mockCache = SearchUsersCache()
        mockTransport = MockTransportSession(dispatchGroup: dispatchGroup)
    }

    override func tearDown() {
        mockCache = nil
        mockTransport = nil

        super.tearDown()
    }

    func testThatItEmptiesTheSearchUserCacheOnTeardown() {
        // given
        let uuid = UUID()
        let sut = makeSearchDirectory()
        insertSearchUser(remoteIdentifier: uuid)

        XCTAssertNotNil(mockCache.object(forKey: uuid as NSUUID))

        // when
        sut.tearDown()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(mockCache.object(forKey: uuid as NSUUID))
    }

    // MARK: - Helpers

    private func makeSearchDirectory() -> SearchDirectory {
        SearchDirectory(
            searchContext: searchMOC,
            contextProvider: coreDataStack!,
            transportSession: mockTransport,
            searchUsersCache: mockCache,
            refreshUsersMissingMetadataAction: .dummy,
            refreshConversationsMissingMetadataAction: .dummy
        )
    }

    private func insertSearchUser(remoteIdentifier: UUID) {
        _ = ZMSearchUser(
            contextProvider: coreDataStack!,
            name: "John Doe",
            handle: "john",
            accentColor: .amber,
            remoteIdentifier: remoteIdentifier,
            searchUsersCache: mockCache
        )
    }
}
