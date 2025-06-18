//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class UserConnectionEventNotificationBuilderTests: XCTestCase {
    private var sut: UserConnectionEventNotificationBuilder!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        userLocalStore = nil
        conversationLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    func testGenerateUserConnectionNotifications() async {
        // Given
        let connectionEvents = [
            Scaffolding.userPendingConnectionEvent,
            Scaffolding.userAcceptedConnectionEvent,
            Scaffolding.userPendingConnectionEventNoUsername,
            Scaffolding.userAcceptedConnectionEventNoUsername
        ]

        // Mock

        userLocalStore.fetchSelfUser_MockValue = await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
        }

        userLocalStore.fetchOrCreateUserIdDomain_MockValue = await context.perform { [self] in
            modelHelper.createUser(in: context)
        }

        userLocalStore.nameFor_MockValue = await context.perform {
            .some(nil)
        }

        userLocalStore.idFor_MockValue = .mockID1

        for connectionEvent in connectionEvents {
            // When
            sut = UserConnectionEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init()
            )

            let userNotification = await sut.buildContent(event: connectionEvent)

            guard case let .text(notificationContent) = userNotification else {
                return
            }

            // Then
            XCTAssertEqual(notificationContent.title, "")
            XCTAssertEqual(notificationContent.sound, UNNotificationSound(named: .init("default")))

            switch connectionEvent.connection.status {

            case .pending:
                if let userName = connectionEvent.userName {
                    XCTAssertEqual(notificationContent.body, "\(Scaffolding.username) wants to connect")
                } else {
                    XCTAssertEqual(notificationContent.body, "Someone wants to connect")
                }

                XCTAssertEqual(
                    notificationContent.categoryIdentifier,
                    NotificationCategory.incomingConnectionRequest.rawValue
                )

            case .accepted:
                if let userName = connectionEvent.userName {
                    XCTAssertEqual(notificationContent.body, "You and \(Scaffolding.username) are now connected")
                } else {
                    XCTAssertEqual(notificationContent.body, "You have a new connection")
                }

                XCTAssertEqual(notificationContent.categoryIdentifier, NotificationCategory.nonActionable.rawValue)

            default:
                XCTFail()
            }
        }
    }

    private enum Scaffolding {
        static let username = "username1"
        static let userPendingConnectionEvent = UserConnectionEvent(
            userName: Scaffolding.username,
            connection: pendingConnection
        )

        static let userPendingConnectionEventNoUsername = UserConnectionEvent(
            userName: nil,
            connection: pendingConnection
        )

        static let userAcceptedConnectionEvent = UserConnectionEvent(
            userName: Scaffolding.username,
            connection: acceptedConnection
        )

        static let userAcceptedConnectionEventNoUsername = UserConnectionEvent(
            userName: nil,
            connection: acceptedConnection
        )

        static let pendingConnection = Connection(
            senderID: .mockID1,
            receiverID: .mockID2,
            receiverQualifiedID: nil,
            conversationID: nil,
            qualifiedConversationID: nil,
            lastUpdate: .distantPast,
            status: .pending
        )

        static let acceptedConnection = Connection(
            senderID: .mockID1,
            receiverID: .mockID2,
            receiverQualifiedID: nil,
            conversationID: nil,
            qualifiedConversationID: nil,
            lastUpdate: .distantPast,
            status: .accepted
        )
    }

}
