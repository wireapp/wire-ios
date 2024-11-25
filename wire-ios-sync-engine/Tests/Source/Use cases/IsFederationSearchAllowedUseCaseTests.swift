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

import WireDataModelSupport
import XCTest

@testable import WireSyncEngine

final class IsFederationSearchAllowedUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: IsFederationSearchAllowedUseCase!
    private let coreDataStackHelper = CoreDataStackHelper()
    private let modelHelper = ModelHelper()
    private var stack: CoreDataStack!
    private var syncContext: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - setUp
    
    override func setUp() async throws {
        try await super.setUp()

        stack = try await coreDataStackHelper.createStack()
        sut = IsFederationSearchAllowedUseCase(syncContext: syncContext, defaultProtocol: .mls)
    }
    
    // MARK: - tearDown
    
    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()

        try await super.tearDown()
    }

    // MARK: - Tests

    func testThatItCanNotAddFederatedUsersToTheProteusConversation() async {
        // GIVEN
        let conversationProtocol = await syncContext.perform {
            let conversation = self.modelHelper.createGroupConversation(in: self.syncContext)
            conversation.messageProtocol = .proteus
            return conversation.messageProtocol
        }

        // WHEN
        let canAddFederatedUsers = sut.invoke(conversationProtocol: conversationProtocol)

        // THEN
        XCTAssertEqual(canAddFederatedUsers, false)
    }

    func testThatItCanAddFederatedUsersToTheMLSConversation() async {
        // GIVEN
        let groupID = MLSGroupID.random()
        let conversationProtocol = await syncContext.perform {
            let conversation = self.modelHelper.createGroupConversation(in: self.syncContext)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            return conversation.messageProtocol
        }

        // WHEN
        let canAddFederatedUsers = sut.invoke(conversationProtocol: conversationProtocol)

        // THEN
        XCTAssertEqual(canAddFederatedUsers, true)
    }

    func testThatItCanSearchForFederatedUsersIfDefaultProtocolIsMLS() {
        // WHEN
        let canSearchFederatedUsers = sut.invoke(conversationProtocol: nil)

        // THEN
        XCTAssertEqual(canSearchFederatedUsers, true)
    }

    func testThatItCanNotSearchForFederatedUsersIfDefaultProtocolIsProteus() {
        // GIVEN
        sut = IsFederationSearchAllowedUseCase(syncContext: syncContext, defaultProtocol: .proteus)

        // WHEN
        let canSearchFederatedUsers = sut.invoke(conversationProtocol: nil)

        // THEN
        XCTAssertEqual(canSearchFederatedUsers, false)
    }

}
