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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireDataModel

final class ConnectionValidatorTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var context: NSManagedObjectContext { coreDataStack.syncContext }
    private var sut: ConnectionValidator!
    private var modelHelper: ModelHelper!
    private var mockActionHandler: MockActionHandler<UpdateConnectionAction>?

    private var team: Team!
    private var selfUser: ZMUser!

    override func setUp() async throws {
        coreDataStack = try await CoreDataStackHelper().createStack()
        sut = ConnectionValidator(context: context)
        modelHelper = ModelHelper()

        try await context.perform { [self] in
            // Team
            team = Team.fetchOrCreate(with: UUID(), in: context)

            // Self User
            selfUser = ZMUser.selfUser(in: context)
            selfUser.remoteIdentifier = UUID()
            selfUser.domain = nil
            selfUser.teamIdentifier = team.remoteIdentifier
            let member = Member.insertNewObject(in: context)
            member.user = selfUser
            member.team = team

            try context.save()
        }
    }

    override func tearDown() {
        coreDataStack = nil
        sut = nil
        modelHelper = nil
        mockActionHandler = nil

        team = nil
        selfUser = nil
    }

    func testCleanUpAllInvalidConnections_whenConversationsShouldBeUnlinked() async throws {
        // Given open connections with `invalid` or `connection` type conversations
        let connectionStatuses: [ZMConnectionStatus] = [
            .invalid,
            .pending,
            .ignored,
            .sent,
            .cancelled,
            .blockedMissingLegalholdConsent
        ]
        let conversationTypes: [ZMConversationType] = [.invalid, .connection]

        let conversations = await context.perform { [self] in
            product(connectionStatuses, conversationTypes).map { status, conversationType in
                makeConversationWithConnection(status: status, type: conversationType)
            }
        }

        XCTAssertEqual(conversations.count, 12)

        mockActionHandler = MockActionHandler<UpdateConnectionAction>(context: context.notificationContext) { _ in
            .success(())
        }

        // When
        try await sut.cleanUpAllInvalidConnections()

        // Then the conversations are unlinked from the one-on-one user
        await context.perform {
            for conversation in conversations {
                XCTAssertEqual(conversation.conversationType, .invalid)
                XCTAssertNil(conversation.oneOnOneUser)
            }
        }
    }

    func testCleanUpAllInvalidConnections_whenConversationsShouldNotBeUnlinked() async throws {
        // Given open connections with `self`, `oneOnOne` or `group` type conversations
        // OR closed connections with `invalid` or `connection` type conversations
        let keepStatuses: [ZMConnectionStatus] = [.accepted, .blocked]
        let keepConversationTypes: [ZMConversationType] = [.self, .oneOnOne, .group]

        let variations = product(ZMConnectionStatus.allCases, ZMConversationType.allCases).filter { status, type in
            keepStatuses.contains(status) || keepConversationTypes.contains(type)
        }

        let conversations = await context.perform { [self] in
            variations.map { status, conversationType in
                makeConversationWithConnection(status: status, type: conversationType)
            }
        }
        let conversationSnapshots = await context.perform { conversations.map(ConversationSnapshot.init) }

        XCTAssertEqual(conversations.count, 28)

        mockActionHandler = MockActionHandler<UpdateConnectionAction>(context: context.notificationContext) { _ in
            .success(())
        }

        // When
        try await sut.cleanUpAllInvalidConnections()

        // Then the conversations are not mutated
        let newSnapshots = await context.perform { conversations.map(ConversationSnapshot.init) }
        XCTAssertEqual(newSnapshots, conversationSnapshots)
    }

    // MARK: Helpers

    private func makeConversationWithConnection(
        status: ZMConnectionStatus,
        type: ZMConversationType
    ) -> ZMConversation {
        let conversation = ZMConversation.fetchOrCreate(with: .init(), domain: nil, in: context)
        conversation.conversationType = type

        let user = ZMUser.fetchOrCreate(with: UUID(), domain: nil, in: context)
        modelHelper.addUser(user, to: team, in: context)

        let connection = ZMConnection.create(userID: user.remoteIdentifier, domain: nil, in: context)
        connection.status = status
        connection.to?.oneOnOneConversation = conversation

        return conversation
    }

    private func product<T, U>(_ aCollection: [T], _ bCollection: [U]) -> [(T, U)] {
        aCollection.flatMap { a in
            bCollection.map { b in
                (a, b)
            }
        }
    }
}

// MARK: - Helpers

/// Takes a snapshot of a conversation for comparison.

private struct ConversationSnapshot: Equatable {
    let remoteIdentifier: UUID
    let conversationType: ZMConversationType
    let oneOnOneUser: UUID?

    init(_ conversation: ZMConversation) {
        self.remoteIdentifier = conversation.remoteIdentifier
        self.conversationType = conversation.conversationType
        self.oneOnOneUser = conversation.oneOnOneUser?.remoteIdentifier
    }
}

private extension ZMConnectionStatus {
    static var allCases: [ZMConnectionStatus] {
        [
            .invalid,
            .accepted,
            .pending,
            .ignored,
            .blocked,
            .sent,
            .cancelled,
            .blockedMissingLegalholdConsent
        ]
    }
}

private extension ZMConversationType {
    static var allCases: [ZMConversationType] {
        [
            .invalid,
            .self,
            .oneOnOne,
            .group,
            .connection
        ]
    }
}
