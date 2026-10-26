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

import GenericMessageProtocol
import XCTest

@testable import WireDataModel
@testable import WireRequestStrategy

final class MessageDependencyResolverTests: MessagingTestBase {

    func testDependencyResolvedDuringFirstReadDoesNotLoseItsWakeup() async {
        let message = ResolvingDependencyMessage(
            message: GenericMessage(content: Text(content: "queued")), context: syncMOC,
            conversation: groupConversation, completionHandler: nil
        )
        let resolver = MessageDependencyResolver(context: syncMOC)
        let completed = expectation(description: "dependency wakeup retained")
        let waiter = Task {
            do {
                try await resolver.waitForDependenciesToResolve(for: message)
                completed.fulfill()
            } catch {}
        }

        await fulfillment(of: [completed], timeout: 1)

        waiter.cancel()
        await waiter.value
    }

    func testCancelledDependencyWaitThrowsWithoutClaimingTheMessage() async throws {
        let message = try await syncMOC.perform {
            let row = try XCTUnwrap(self.groupConversation.appendText(content: "queued") as? ZMClientMessage)
            try row.enqueueInOutbox(operation: .initialMessage)
            try self.syncMOC.save()
            return row
        }
        let resolver = MessageDependencyResolver(context: syncMOC)
        let waiter = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await resolver.waitForDependenciesToResolve(for: message)
        }

        do {
            try await waiter.value
            XCTFail("A cancelled dependency wait must throw")
        } catch is CancellationError {} catch {
            XCTFail("Unexpected cancellation error: \(error)")
        }
        await syncMOC.perform {
            XCTAssertEqual(message.outboxState, .queued)
            XCTAssertNil(message.outboxAttemptIdentifier)
            XCTAssertFalse(message.isExpired)
        }
    }

    func testClosedContextRejectsDependencyReadsOfAResetMessage() async throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = syncMOC.persistentStoreCoordinator
        context.performAndWait { context.markAsSyncContext() }
        let message = try await context.perform {
            let conversation = try XCTUnwrap(context.existingObject(with: self.groupConversation.objectID) as? ZMConversation)
            return try XCTUnwrap(conversation.appendText(content: "queued") as? ZMClientMessage)
        }
        context.tearDown()

        do {
            try await MessageDependencyResolver(context: context).waitForDependenciesToResolve(for: message)
            XCTFail("A reset message must not be read")
        } catch {
            XCTAssertEqual(error as? MessageOutboxError, .staleAttempt)
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
}

private final class ResolvingDependencyMessage: GenericMessageEntity {
    private var checkedDependency = false

    override var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        // Deliver the only wakeup inside the initial read while still reporting a dependency.
        // Subscribing after that read would wait forever; the next read intentionally returns nil.
        guard !checkedDependency else { return nil }
        checkedDependency = true
        NotificationCenter.default.post(name: .requestAvailableNotification, object: nil)
        return NSObject()
    }
}
