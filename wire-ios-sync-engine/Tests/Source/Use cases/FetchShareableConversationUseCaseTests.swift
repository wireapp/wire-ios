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
@testable import WireDataModelSupport
@testable import WireSyncEngine

class FetchShareableConversationUseCaseTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = FetchShareableConversationsUseCase(contextProvider: coreDataStack)
    }

    override func tearDown() {
        sut = nil
        coreDataStack = nil
        coreDataStackHelper = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInvoke() {
        // Given
        let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)

        // create a shareable conversation
        let shareable = createConversation()
        shareable.addParticipantAndUpdateConversationState(user: selfUser)

        // create a non-shareable conversation
        createConversation()

        // When
        let result = sut.invoke()

        // Then
        XCTAssertEqual(result, [shareable])
    }

    // MARK: Private

    // MARK: - Properties

    private var sut: FetchShareableConversationsUseCase!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    // MARK: - Helpers

    @discardableResult
    private func createConversation() -> ZMConversation {
        let context = coreDataStack.viewContext

        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.isArchived = false
        conversation.messageProtocol = .proteus
        conversation.conversationType = .group

        return conversation
    }
}
