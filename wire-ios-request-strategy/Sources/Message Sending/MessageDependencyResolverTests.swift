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
@testable import WireDataModel

final class MessageDependencyResolverTests: MessagingTestBase {
    struct Arrangement {
        enum Scaffolding {
            static let clientID = QualifiedClientID(userID: UUID(), domain: "example.com", clientID: "client123")
            static let prekey = Payload.Prekey(key: "prekey123", id: nil)
            static let prekeyByQualifiedUserID =
                [clientID.domain: [clientID.userID.transportString(): [clientID.clientID: prekey]]]
        }

        let coreDataStack: CoreDataStack

        func arrange() -> (Arrangement, MessageDependencyResolver) {
            (
                self,
                MessageDependencyResolver(context: coreDataStack.syncContext)
            )
        }
    }

    func testThatGivenMessageWithoutDependencies_thenDontWait() async throws {
        // given
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // then test completes
        let before = Date.now
        try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        XCTAssert(Date.now.timeIntervalSince(before) < 0.5, "duration > 500ms")
    }

    func testThatGivenMessageIsInvisibleAndConversationIsDegraded_thenDontThrow() async throws {
        // given
        await syncMOC.perform { [self] in
            groupConversation.messageProtocol = .mls
            groupConversation.mlsVerificationStatus = .degraded
        }

        let uuid = UUID.create()
        let message = GenericMessageEntity(
            message: GenericMessage(content: Confirmation(messageId: uuid)),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        message.shouldIgnoreTheSecurityLevelCheck = true
        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // then test completes
        let before = Date.now
        try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        XCTAssert(Date.now.timeIntervalSince(before) < 0.5, "duration > 500ms")
    }

    func testThatGivenMessageWithDependencies_thenWaitUntilDependencyIsResolved() async throws {
        // given
        await syncMOC.perform {
            // make conversatio sync a dependency
            self.groupConversation.needsToBeUpdatedFromBackend = true
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // Sleeping in order to hit the code path where we start observing RequestAvailable
        try await Task.sleep(nanoseconds: 250_000_000)

        await syncMOC.perform {
            self.groupConversation.needsToBeUpdatedFromBackend = false
        }

        RequestAvailableNotification.notifyNewRequestsAvailable(nil)

        // then test completes
        let before = Date.now
        try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        XCTAssert(Date.now.timeIntervalSince(before) < 0.5, "duration > 500ms")
    }

    func testThatGivenMessageWithLegalHoldStatusPendingApproval_thenThrow() async throws {
        // given
        await syncMOC.perform { [self] in
            // make conversatio sync a dependency
            groupConversation.needsToBeUpdatedFromBackend = true
            groupConversation.legalHoldStatus = .pendingApproval
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // then test completes
        do {
            try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
            XCTFail("unexpected success")
        } catch MessageDependencyResolverError.legalHoldPendingApproval {
            // should pass here
        } catch {
            XCTFail(String(reflecting: error))
        }
    }
}
