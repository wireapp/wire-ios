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

import WireAPI
import XCTest

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

    func testGetConversationIdentifiers_givenAPIVersionV0() async throws {
        try await snapshotHelper.verifyRequestForAllAPIVersions { sut in
            let pager = try await sut.getConversationIdentifiers()
            for try await _ in pager {
                // this triggers fetching the data
            }
        }
    }

}
