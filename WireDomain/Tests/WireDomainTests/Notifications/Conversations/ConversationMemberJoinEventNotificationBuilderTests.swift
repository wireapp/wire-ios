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
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationMemberJoinEventNotificationBuilderTests: XCTestCase {
    private var sut: ConversationMemberJoinEventNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!

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
        conversationLocalStore = nil
        userLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    func testGenerateConversationMemberJoinEventNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, participants: [])

        sut = ConversationMemberJoinEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserAddedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )
    }

    func testGenerateConversationMemberJoinEventNotification_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam, participants: [])

        sut = ConversationMemberJoinEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserAddedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )
    }

    func testGenerateConversationMemberJoinEventNotification_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, participants: [])

        sut = ConversationMemberJoinEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserAddedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )

    }

    func testGenerateConversationMemberJoinEventNotification_It_Should_Not_Build_Notification() async throws {
        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, participants: [])

        sut = ConversationMemberJoinEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.otherUserAddedEvent)

        // Then
        XCTAssertNil(userNotification)
    }

    func test_ItDoesNotCreateNotification_WhenSelfUserIsAlreadyParticipant() async throws {
        // Given
        let selfUser = await context.perform { [modelHelper, context] in
            modelHelper.createSelfUser(id: Scaffolding.selfUserID, in: context)
        }

        // Mock
        await setupMock(isGroup: true, isTeam: false, participants: [selfUser])

        sut = ConversationMemberJoinEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore
            )
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserAddedEvent)

        // Then: should NOT create notification
        XCTAssertNil(userNotification, "Should not create notification when self user is already a participant")
    }

    private func internalTest_assertNotificationContent(
        _ userNotification: UserNotification,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {

        guard case let .text(notificationContent) = userNotification else {
            return XCTFail()
        }

        // Title
        if isGroup {
            XCTAssertEqual(
                notificationContent.title,
                isTeam ? "\(Scaffolding.conversationName) in \(Scaffolding.teamName)" :
                    "\(Scaffolding.conversationName)"
            )
        } else {
            XCTAssertEqual(
                notificationContent.title,
                isTeam ? "\(Scaffolding.senderName) in \(Scaffolding.teamName)" : "\(Scaffolding.senderName)"
            )
        }

        // Body
        XCTAssertEqual(
            notificationContent.body,
            "\(Scaffolding.senderName) added you"
        )

        // Category
        XCTAssertEqual(
            notificationContent.categoryIdentifier,
            NotificationCategory.unmutedConversation.rawValue
        )

        // Sound
        XCTAssertEqual(
            notificationContent.sound,
            UNNotificationSound(named: .init("default"))
        )

        // Thread ID
        XCTAssertEqual(
            notificationContent.threadIdentifier,
            Scaffolding.conversationID.id.uuidString.lowercased()
        )

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! String, UUID.mockID1.uuidString)
        XCTAssertEqual(notificationContent.userInfo["senderIDString"] as! String, UUID.mockID3.uuidString)
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! String, UUID.mockID2.uuidString)
    }

    private func setupMock(isGroup: Bool, isTeam: Bool, participants: Set<ZMUser>) async {
        let conversation = await context.perform { [modelHelper, context] in
            modelHelper.createGroupConversation(in: context)
        }
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.fetchConversationIdDomain_MockValue = conversation
        conversationLocalStore.localParticipantsIn_MockValue = participants
        conversationLocalStore.conversationMutedMessageTypesIncludingAvailability_MockValue = .some(.none)
        conversationLocalStore.lastReadServerTimestamp_MockValue = .now
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = await context.perform { [modelHelper, context] in
            modelHelper.createUser(in: context)
        }
        userLocalStore.nameFor_MockValue = Scaffolding.senderName
        conversationLocalStore.nameFor_MockValue = Scaffolding.conversationName
        conversationLocalStore.isGroupConversation_MockValue = isGroup
        userLocalStore.fetchSelfUser_MockValue = await context.perform { [modelHelper, context] in
            modelHelper.createSelfUser(id: Scaffolding.selfUserID, in: context)
        }
        conversationLocalStore.isConversationForcedReadOnly_MockValue = false
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        userLocalStore.idFor_MockValue = Scaffolding.selfUserID
        userLocalStore.teamNameFor_MockValue = .some(isTeam ? Scaffolding.teamName : nil)
        conversationLocalStore.shouldHideNotification_MockValue = false
        conversationLocalStore.decreaseUnreadCountFor_MockMethod = { _ in }
    }

    private enum Scaffolding {
        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
        static let selfUserID = UUID.mockID1

        static let selfUserAddedEvent = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: userID,
            timestamp: .now,
            members: [selfMember]
        )

        static let otherUserAddedEvent = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: userID,
            timestamp: .now,
            members: [otherMember]
        )

        static let selfMember = Conversation.Member(
            qualifiedID: nil,
            id: selfUserID, // self user was added, notification will be processed
            qualifiedTarget: nil,
            target: nil,
            conversationRole: nil,
            service: nil,
            archived: nil,
            archivedReference: nil,
            hidden: nil,
            hiddenReference: nil,
            mutedStatus: nil,
            mutedReference: nil
        )

        static let otherMember = Conversation.Member(
            qualifiedID: nil,
            id: .mockID4, // self user was NOT added, notification will not be processed
            qualifiedTarget: nil,
            target: nil,
            conversationRole: nil,
            service: nil,
            archived: nil,
            archivedReference: nil,
            hidden: nil,
            hiddenReference: nil,
            mutedStatus: nil,
            mutedReference: nil
        )
    }
}
