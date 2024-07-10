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

import WireAPISupport
import WireDomain
import XCTest

final class ConversationRepositoryTests: XCTestCase {

    private var mockConversationsAPI: MockConversationsAPI!

    override func setUp() {
        super.setUp()
        mockConversationsAPI = MockConversationsAPI()
    }

    override func tearDown() {
        mockConversationsAPI = nil
        super.tearDown()
    }

    func testUpdateGroupIcon() async throws {
        // given
        let expectation = self.expectation(description: "")

        mockConversationsAPI.updateGroupIcon_MockMethod = {
            expectation.fulfill()
        }

        let repository = makeRepository()

        // when
        try await repository.updateGroupIcon()

        // then
        await fulfillment(of: [expectation], timeout: 0.1)
    }

    // MARK: Helpers

    private func makeRepository() -> ConversationRepository {
        ConversationRepository(conversationAPI: mockConversationsAPI)
    }
}
