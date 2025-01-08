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

final class NewSystemMessageNotificationBuilderTests: XCTestCase {
    private var sut: NewSystemMessageNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
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
        messageLocalStore = MockMessageLocalStoreProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        registerDependencies()
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        conversationLocalStore = nil
        messageLocalStore = nil
        userLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    private func registerDependencies() {
        Injector.register(ConversationLocalStoreProtocol.self) {
            self.conversationLocalStore
        }

        Injector.register(UserLocalStoreProtocol.self) {
            self.userLocalStore
        }

        Injector.register(MessageLocalStoreProtocol.self) {
            self.messageLocalStore
        }
    }

    func testGenerateNewSystemMessageNotifications_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, selfUserID: .mockID4)

        let systemMessages: [NewSystemMessageNotificationBuilder.SystemMessage] = [
            .memberLeave(removedUserIDs: [.mockID4]) // concerns self user
        ]

        for systemMessage in systemMessages {
            sut = await NewSystemMessageNotificationBuilder(
                systemMessage: systemMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let notificationContent = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notificationContent,
                systemMessage: systemMessage,
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    func testGenerateNewSystemMessageNotifications_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam, selfUserID: .mockID4)

        let systemMessages: [NewSystemMessageNotificationBuilder.SystemMessage] = [
            .memberLeave(removedUserIDs: [.mockID4]) // concerns self user
        ]

        for systemMessage in systemMessages {
            sut = await NewSystemMessageNotificationBuilder(
                systemMessage: systemMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let notificationContent = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notificationContent,
                systemMessage: systemMessage,
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    func testGenerateNewSystemMessageNotifications_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, selfUserID: .mockID4)

        let systemMessages: [NewSystemMessageNotificationBuilder.SystemMessage] = [
            .memberLeave(removedUserIDs: [.mockID4]) // concerns self user
        ]

        for systemMessage in systemMessages {
            sut = await NewSystemMessageNotificationBuilder(
                systemMessage: systemMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let notificationContent = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notificationContent,
                systemMessage: systemMessage,
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    func testGenerateNewSystemMessageNotifications_Notification_Is_Empty_When_User_Is_Not_Self() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, selfUserID: .mockID3)

        let systemMessages: [NewSystemMessageNotificationBuilder.SystemMessage] = [
            .memberLeave(removedUserIDs: [UUID()]) // doesn't concern self user
        ]

        for systemMessage in systemMessages {
            sut = await NewSystemMessageNotificationBuilder(
                systemMessage: systemMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()

            XCTAssertEqual(shouldBuildNotification, false) // user is not self user
        }
    }

    private func internalTest_assertNotificationContent(
        _ notificationContent: UNMutableNotificationContent,
        systemMessage: NewSystemMessageNotificationBuilder.SystemMessage,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {

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

        switch systemMessage {
        case .memberLeave:
            XCTAssertEqual(notificationContent.body, "\(Scaffolding.senderName) removed you")
        case .conversationCreated:
            break
        case .memberJoin:
            break
        case .conversationDeleted:
            break
        case .messageTimerUpdate:
            break
        }

        // Category
        XCTAssertEqual(
            notificationContent.categoryIdentifier,
            NotificationCategory.unmutedConversation.rawValue
        )

        // Sound
        XCTAssertEqual(notificationContent.sound, UNNotificationSound(named: .init("default")))

        // Thread ID
        XCTAssertEqual(
            notificationContent.threadIdentifier,
            Scaffolding.conversationID.uuid.uuidString.lowercased()
        )

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! UUID, .mockID4)
        XCTAssertEqual(notificationContent.userInfo["senderIDString"] as! UUID, .mockID3)
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! UUID, .mockID2)

    }

    private func setupMock(
        isGroup: Bool,
        isTeam: Bool,
        selfUserID: UUID
    ) async {
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.conversationMutedMessageTypesIncludingAvailability_MockValue = .some(.none)
        conversationLocalStore.lastReadServerTimestamp_MockValue = .now
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = await context.perform { [self] in
            modelHelper.createUser(in: context)
        }
        userLocalStore.nameFor_MockValue = Scaffolding.senderName
        conversationLocalStore.nameFor_MockValue = Scaffolding.conversationName
        conversationLocalStore.isGroupConversation_MockValue = isGroup
        userLocalStore.fetchSelfUser_MockValue = await context.perform { [self] in
            modelHelper.createSelfUser(id: selfUserID, in: context)
        }
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        userLocalStore.idFor_MockValue = selfUserID
        userLocalStore.teamNameFor_MockValue = .some(isTeam ? Scaffolding.teamName : nil)
        conversationLocalStore.shouldHideNotification_MockValue = false
        messageLocalStore.fetchMessageIdConversationIDConversationDomain_MockValue = await context.perform { [self] in
            ZMOTRMessage.fetch(withNonce: .mockID1, for: conversation, in: context)
        }
        messageLocalStore.isMessageMentioningSelfText_MockValue = false
        messageLocalStore.isMessageQuotingSelfQuotedMessage_MockValue = false
    }

    private enum Scaffolding {
        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireAPI.QualifiedID(uuid: .mockID2, domain: "domain.com")
        static let userID = UserID(uuid: .mockID3, domain: "domain.com")
    }
}
