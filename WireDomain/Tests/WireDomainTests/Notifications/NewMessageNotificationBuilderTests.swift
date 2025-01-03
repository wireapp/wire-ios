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

final class NewMessageNotificationBuilderTests: XCTestCase {
    private var sut: NewMessageNotificationBuilder!
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

    func testGenerateNewMessageNotifications_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let messagesCapable = getAllMessagesCapable()

        for messageCapable in messagesCapable {
            let genericMessage = GenericMessage(content: messageCapable)
            sut = await NewMessageNotificationBuilder(
                message: genericMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let notification = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notification,
                messageContent: try XCTUnwrap(genericMessage.content),
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    func testGenerateNewMessageNotifications_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let messagesCapable = getAllMessagesCapable()

        for messageCapable in messagesCapable {
            let genericMessage = GenericMessage(content: messageCapable)
            sut = await NewMessageNotificationBuilder(
                message: genericMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let notification = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notification,
                messageContent: try XCTUnwrap(genericMessage.content),
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    func testGenerateNewMessageNotifications_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let messagesCapable = getAllMessagesCapable()

        for messageCapable in messagesCapable {
            let genericMessage = GenericMessage(content: messageCapable)
            sut = await NewMessageNotificationBuilder(
                message: genericMessage,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let notificationContent = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                notificationContent,
                messageContent: try XCTUnwrap(genericMessage.content),
                isGroup: isGroup,
                isTeam: isTeam
            )

        }
    }

    private func internalTest_assertNotificationContent(
        _ notificationContent: UNMutableNotificationContent,
        messageContent: GenericMessage.OneOf_Content,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {

        // Title
        switch messageContent {
        case .ephemeral, .hidden:
            XCTAssert(notificationContent.title.isEmpty)
        default:
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
        }

        // Body
        switch messageContent {
        case .image:
            XCTAssertEqual(
                notificationContent.body,
                isGroup ? "\(Scaffolding.senderName) shared a picture" : "Shared a picture"
            )
        case let .asset(asset):
            switch asset.original.metaData {
            case .image:
                XCTAssertEqual(
                    notificationContent.body,
                    isGroup ? "\(Scaffolding.senderName) shared a picture" : "Shared a picture"
                )
            case .video:
                XCTAssertEqual(
                    notificationContent.body,
                    isGroup ? "\(Scaffolding.senderName) shared a video" : "Shared a video"
                )
            case .audio:
                XCTAssertEqual(
                    notificationContent.body,
                    isGroup ? "\(Scaffolding.senderName) shared an audio message" : "Shared an audio message"
                )
            default:
                XCTAssertEqual(
                    notificationContent.body,
                    isGroup ? "\(Scaffolding.senderName) shared a file" : "Shared a file"
                )
            }
        case .knock:
            XCTAssertEqual(notificationContent.body, isGroup ? "\(Scaffolding.senderName) pinged you" : "Pinged you")
        case .text, .composite:
            XCTAssertEqual(notificationContent.body, "\(Scaffolding.senderName): Hello")
        case .hidden:
            XCTAssertEqual(notificationContent.body, "New message")
        case .location:
            XCTAssertEqual(
                notificationContent.body,
                isGroup ? "\(Scaffolding.senderName) shared a location" : "Shared a location"
            )
        case .ephemeral:
            XCTAssertEqual(notificationContent.body, "Someone sent a message")
        default:
            XCTFail("Not handled")
        }

        XCTAssert(!notificationContent.body.isEmpty)

        // Category
        XCTAssertEqual(
            notificationContent.categoryIdentifier,
            NotificationCategory.unmutedConversation.rawValue
        )

        // Sound
        switch messageContent {
        case .knock:
            XCTAssertEqual(notificationContent.sound, UNNotificationSound(named: .init("ping_from_them.caf")))
        default:
            XCTAssertEqual(notificationContent.sound, UNNotificationSound(named: .init("default")))
        }

        // Thread ID
        switch messageContent {
        case .ephemeral:
            XCTAssertEqual(notificationContent.threadIdentifier, "")
        default:
            XCTAssertEqual(
                notificationContent.threadIdentifier,
                Scaffolding.conversationID.uuid.uuidString.lowercased()
            )
        }

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! UUID, .mockID1)
        XCTAssertEqual(notificationContent.userInfo["senderIDString"] as! UUID, .mockID3)
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! UUID, .mockID2)

    }

    private func getAllMessagesCapable() -> [MessageCapable] {
        var composite = Composite()
        var textItem = Composite.Item()
        textItem.text = Text(content: "Hello")
        composite.items = [textItem]

        var audioAsset = Asset()
        audioAsset.original.metaData = .audio(Asset.AudioMetaData())

        var videoAsset = Asset()
        videoAsset.original.metaData = .video(Asset.VideoMetaData())

        var imageAsset = Asset()
        imageAsset.original.metaData = .image(Asset.ImageMetaData())

        return [
            Location(),
            Knock(),
            ImageAsset(),
            Ephemeral(),
            Text(content: "Hello"),
            composite,
            Asset(),
            audioAsset,
            videoAsset,
            imageAsset,
            MessageHide()
        ]
    }

    private func setupMock(isGroup: Bool, isTeam: Bool) async {
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
            modelHelper.createSelfUser(in: context)
        }
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        userLocalStore.idFor_MockValue = .mockID1
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
