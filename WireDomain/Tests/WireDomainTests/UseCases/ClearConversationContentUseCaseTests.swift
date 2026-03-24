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

import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class ClearConversationContentUseCaseTests: XCTestCase {

    private var sut: ClearConversationContentUseCase!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private let conversationID = QualifiedID(uuid: UUID(), domain: "wire.com")
    
    private var context: NSManagedObjectContext { stack.syncContext }

    // MARK: - Life cycle

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        sut = ClearConversationContentUseCase(conversationID: conversationID, syncContext: context)
    }

    override func tearDown() async throws {
        sut = nil
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }


    // MARK: - Tests

    func testInvoke_SetsClearedTimestampToLastServerTimestamp() async throws {
        // Given
        let lastServerTimestamp = Date()
        let id = conversationID.uuid
        let domain = conversationID.domain

        await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(id: id, domain: domain, in: context)
            conversation.lastServerTimeStamp = lastServerTimestamp
        }
        
        // When
        await sut.invoke()

        // Then
        let clearedTimestamp = await context.perform { [context] in
            ZMConversation.fetch(with: id, domain: domain, in: context)?.clearedTimeStamp
        }

        XCTAssertEqual(clearedTimestamp, lastServerTimestamp)
    }

    func testInvoke_SetsLastReadServerTimestampToLastServerTimestamp() async throws {
        // Given
        let lastServerTimestamp = Date()

        await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(id: conversationID.uuid, domain: conversationID.domain, in: context)
            conversation.lastServerTimeStamp = lastServerTimestamp
        }

        // When
        await sut.invoke()

        // Then
        let lastReadTimestamp = await context.perform { [self] in
            ZMConversation.fetch(with: conversationID.uuid, domain: conversationID.domain, in: context)?.lastReadServerTimeStamp
        }

        XCTAssertEqual(lastReadTimestamp, lastServerTimestamp)
    }

    func testInvoke_DeletesMessagesOlderThanOrEqualToClearedTimestamp() async throws {
        // Given
        let baseDate = Date()

        let (olderMessageID, exactMessageID) = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(id: conversationID.uuid  , domain: conversationID.domain, in: context)
            conversation.lastServerTimeStamp = baseDate

            let older = ZMClientMessage(context: context)
            older.visibleInConversation = conversation
            older.serverTimestamp = baseDate.addingTimeInterval(-10)

            let exact = ZMClientMessage(context: context)
            exact.visibleInConversation = conversation
            exact.serverTimestamp = baseDate

            try? context.save()
            return (older.objectID, exact.objectID)
        }
        
        // When
        await sut.invoke()

        // Then
        let (olderDeleted, exactDeleted) = await context.perform { [context] in
            let older = try? context.existingObject(with: olderMessageID)
            let exact = try? context.existingObject(with: exactMessageID)
            return (older?.isDeleted ?? true, exact?.isDeleted ?? true)
        }

        XCTAssertTrue(olderDeleted)
        XCTAssertTrue(exactDeleted)
    }

    func testInvoke_KeepsMessagesNewerThanClearedTimestamp() async throws {
        // Given
        let baseDate = Date()

        let newerMessageID = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(id: conversationID.uuid, domain: conversationID.domain, in: context)
            conversation.lastServerTimeStamp = baseDate

            let newer = ZMClientMessage(context: context)
            newer.visibleInConversation = conversation
            newer.serverTimestamp = baseDate.addingTimeInterval(10)

            try? context.save()
            return newer.objectID
        }

        // When
        await sut.invoke()

        // Then
        let newerDeleted = await context.perform { [context] in
            (try? context.existingObject(with: newerMessageID))?.isDeleted ?? true
        }

        XCTAssertFalse(newerDeleted)
    }

    func testInvoke_PostsClearContentNotification() async throws {
        // Given
        let id = UUID()

        await context.perform { [self] in
            modelHelper.createGroupConversation(id: conversationID.uuid, domain: conversationID.domain, in: context)
        }

        let expectation = XCTNSNotificationExpectation(
            name: .clearContentNotification,
            object: context.notificationContext
        )

        // When
        await sut.invoke()

        // Then
        await fulfillment(of: [expectation], timeout: 1)
    }
}
