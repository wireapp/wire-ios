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

final class CallNotificationBuilderTests: XCTestCase {
    private var sut: CallNotificationBuilder!
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
        registerDependencies()
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

    private func registerDependencies() {
        Injector.register(ConversationLocalStoreProtocol.self) {
            self.conversationLocalStore
        }

        Injector.register(UserLocalStoreProtocol.self) {
            self.userLocalStore
        }
    }

    func testGenerateCallNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callingTestUsecases = getCallingTestUseCases()

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = await CallNotificationBuilder(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let content = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                content,
                callingTestUsecase: callingTestUsecase,
                isGroup: isGroup,
                isTeam: isTeam
            )
        }
    }

    func testGenerateCallNotification_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callingTestUsecases = getCallingTestUseCases()

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = await CallNotificationBuilder(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let content = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                content,
                callingTestUsecase: callingTestUsecase,
                isGroup: isGroup,
                isTeam: isTeam
            )
        }

    }

    func testGenerateCallNotification_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callingTestUsecases = getCallingTestUseCases()

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = await CallNotificationBuilder(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            let content = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                content,
                callingTestUsecase: callingTestUsecase,
                isGroup: isGroup,
                isTeam: isTeam
            )
        }

    }

    func testGenerateCallNotification_Should_Build_Notification_Returns_False() async {
        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        // An example payload that will be treated as an `unhandled` case.
        let unhandledCallJson = """
        {
            "type": "REJECT",
            "src_clientid": "clientid",
            "resp": true,
            "props": { "videosend": "false" }
        }
        """


        var calling = Calling()
        calling.content = unhandledCallJson

        sut = await CallNotificationBuilder(
            calling: calling,
            at: .now,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        let shouldBuildNotification = await sut.shouldBuildNotification()
        XCTAssertEqual(shouldBuildNotification, false)
    }

    private func internalTest_assertNotificationContent(
        _ notificationContent: UNMutableNotificationContent,
        callingTestUsecase: CallingTestUseCase,
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
        switch callingTestUsecase {
        case .incomingAudioCall:
            XCTAssertEqual(
                notificationContent.body,
                isGroup ? "\(Scaffolding.senderName) is calling" : "Incoming call"
            )
        case .incomingVideoCall:
            XCTAssertEqual(
                notificationContent.body,
                isGroup ? "\(Scaffolding.senderName) is calling with video" : "Incoming video call"
            )
        case .missedCall:
            XCTAssertEqual(
                notificationContent.body,
                isGroup ? "\(Scaffolding.senderName) called" : "Missed call"
            )
        }

        // Category
        switch callingTestUsecase {
        case .incomingAudioCall, .incomingVideoCall:
            XCTAssertEqual(
                notificationContent.categoryIdentifier,
                NotificationCategory.incomingCall.rawValue
            )
        case .missedCall:
            XCTAssertEqual(
                notificationContent.categoryIdentifier,
                NotificationCategory.missedCall.rawValue
            )
        }

        // Sound

        switch callingTestUsecase {
        case .incomingAudioCall, .incomingVideoCall:
            XCTAssertEqual(
                notificationContent.sound,
                UNNotificationSound(named: .init("ringing_from_them_long.caf"))
            )
        case .missedCall:
            XCTAssertEqual(
                notificationContent.sound,
                UNNotificationSound(named: .init("default"))
            )
        }

        // Thread ID
        XCTAssertEqual(
            notificationContent.threadIdentifier,
            Scaffolding.conversationID.uuid.uuidString.lowercased()
        )

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! UUID, .mockID1)
        XCTAssertNil(notificationContent.userInfo["senderIDString"])
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! UUID, .mockID2)

    }

    // MARK: - Tested use cases

    private enum CallingTestUseCase {
        case incomingAudioCall(String)
        case incomingVideoCall(String)
        case missedCall(String)

        var json: String {
            switch self {
            case let .incomingAudioCall(string):
                string
            case let .incomingVideoCall(string):
                string
            case let .missedCall(string):
                string
            }
        }
    }

    private func getCallingTestUseCases() -> [CallingTestUseCase] {
        let startAudioCallJson = setupCallingContentMock(type: "SETUP")
        let startVideoCallJson = setupCallingContentMock(type: "SETUP", isVideo: true)
        let endCallJson = setupCallingContentMock(type: "CANCEL")

        return [
            .incomingAudioCall(startAudioCallJson),
            .incomingVideoCall(startVideoCallJson),
            .missedCall(endCallJson)
        ]

    }

    // MARK: - Mocks

    private func setupCallingContentMock(
        type: String,
        isVideo: Bool = false
    ) -> String {
        """
        {
            "type": "\(type)",
            "src_clientid": "clientid",
            "resp": false,
            "props": { "videosend": "\(isVideo)" }
        }
        """
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
    }

    private enum Scaffolding {
        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireAPI.QualifiedID(uuid: .mockID2, domain: "domain.com")
        static let userID = UserID(uuid: .mockID3, domain: "domain.com")
    }

}
