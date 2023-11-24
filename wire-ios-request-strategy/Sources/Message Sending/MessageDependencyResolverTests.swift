//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class MessageDependencyResolverTests: MessagingTestBase {

    func testThatGivenMessageWithoutDependencies_thenDontWait() throws {
        // given
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)
        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        // then test completes
        wait(timeout: 0.5) {
            try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        }
    }

    func testThatGivenMessageWithDependencies_thenWaitUntilDependencyIsResolved() throws {
        // given
        syncMOC.performAndWait {
            // make conversatio sync a dependency
            groupConversation.needsToBeUpdatedFromBackend = true
        }
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)
        let (_, messageDependencyResolver) = Arrangement(coreDataStack: coreDataStack)
            .arrange()

        Task {
            // Sleeping in order to hit the code path where we start observing RequestAvailable
            try await Task.sleep(nanoseconds: 250_000_000)

            syncMOC.performAndWait {
                groupConversation.needsToBeUpdatedFromBackend = false
            }

            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }

        // then test completes
        wait(timeout: 0.5) {
            try await messageDependencyResolver.waitForDependenciesToResolve(for: message)
        }
    }

    struct Arrangement {

        struct Scaffolding {
            static let clientID = QualifiedClientID(userID: UUID(), domain: "example.com", clientID: "client123")
            static let prekey = Payload.Prekey(key: "prekey123", id: nil)
            static let prekeyByQualifiedUserID = [clientID.domain: [clientID.userID.transportString(): [clientID.clientID: prekey]]]
        }

        let coreDataStack: CoreDataStack

        func arrange() -> (Arrangement, MessageDependencyResolver) {
            return (self, MessageDependencyResolver(
                context: coreDataStack.syncContext
                )
            )
        }
    }

}
