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
import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationCallingEventNotificationBuilderTests: XCTestCase {
    private var sut: ConversationCallingEventNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var defaults: UserDefaults!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        defaults = UserDefaults(suiteName: UUID.mockID1.uuidString)!
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: UUID.mockID1.uuidString)
        defaults = nil
        stack = nil
        sut = nil
        conversationLocalStore = nil
        userLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    // MARK: - CallKit Tests

    func testGenerateCallKitNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callKitTestUsecases = getCallKitTestUseCases()

        for callKitTestUsecase in callKitTestUsecases {
            if case .endingCall = callKitTestUsecase {
                let mockHandle =
                    "\(Scaffolding.accountID.uuidString.lowercased())+\(Scaffolding.conversationID.id.uuidString.lowercased())"
                defaults.set([mockHandle], forKey: "knownCalls")
            }

            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: Scaffolding.accountID
            )

            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            try await internalCallKitTest_assertNotificationContent(
                testUsecase: callKitTestUsecase,
                content: try XCTUnwrap(userNotification),
                isGroup: isGroup,
                isTeam: isTeam
            )
        }
    }

    func testGenerateCallKitNotification_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callKitTestUsecases = getCallKitTestUseCases()

        for callKitTestUsecase in callKitTestUsecases {
            if case .endingCall = callKitTestUsecase {
                let mockHandle =
                    "\(Scaffolding.accountID.uuidString.lowercased())+\(Scaffolding.conversationID.id.uuidString.lowercased())"
                defaults.set([mockHandle], forKey: "knownCalls")
            }

            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: Scaffolding.accountID
            )

            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            try await internalCallKitTest_assertNotificationContent(
                testUsecase: callKitTestUsecase,
                content: try XCTUnwrap(userNotification),
                isGroup: isGroup,
                isTeam: isTeam
            )
        }
    }

    func testGenerateCallKitNotification_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callKitTestUsecases = getCallKitTestUseCases()

        for callKitTestUsecase in callKitTestUsecases {
            if case .endingCall = callKitTestUsecase {
                let mockHandle =
                    "\(Scaffolding.accountID.uuidString.lowercased())+\(Scaffolding.conversationID.id.uuidString.lowercased())"
                defaults.set([mockHandle], forKey: "knownCalls")
            }

            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: Scaffolding.accountID
            )

            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            try await internalCallKitTest_assertNotificationContent(
                testUsecase: callKitTestUsecase,
                content: try XCTUnwrap(userNotification),
                isGroup: isGroup,
                isTeam: isTeam
            )
        }
    }

    func testGenerateCallKitNotification_Should_Build_Notification_Returns_False() async {
        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        // An example payload that will be treated as an `unhandled` case.
        let unhandledCallJson = """
        {
            "type": "REMOTEMUTE",
            "src_clientid": "clientid",
            "resp": false,
            "props": { "videosend": "false" }
        }
        """

        var calling = Calling()
        calling.content = unhandledCallJson

        sut = ConversationCallingEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore,
                userDefaults: defaults
            ),
            accountID: .mockID1
        )

        let userNotification = await sut.buildContent(
            calling: calling,
            at: .now,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        XCTAssertNil(userNotification)
    }

    // MARK: - "Regular" notification call tests

    func testGenerateCallNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callingTestUsecases = getCallingTestUseCases()
        defaults.set(false, forKey: "isCallKitAvailable")

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: .mockID1
            )

            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            try await internalTest_assertNotificationContent(
                try XCTUnwrap(userNotification),
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
        defaults.set(false, forKey: "isCallKitAvailable")

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: .mockID1
            )

            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            try await internalTest_assertNotificationContent(
                try XCTUnwrap(userNotification),
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
        defaults.set(false, forKey: "isCallKitAvailable")

        for callingTestUsecase in callingTestUsecases {
            var calling = Calling()
            calling.content = callingTestUsecase.json

            sut = ConversationCallingEventNotificationBuilder(
                context: .init(
                    conversationLocalStore: conversationLocalStore,
                    userLocalStore: userLocalStore
                ),
                validator: .init(
                    userLocalStore: userLocalStore,
                    conversationLocalStore: conversationLocalStore,
                    userDefaults: defaults
                ),
                accountID: .mockID1
            )

            // When
            let userNotification = await sut.buildContent(
                calling: calling,
                at: .now,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID
            )

            // Then
            try await internalTest_assertNotificationContent(
                try XCTUnwrap(userNotification),
                callingTestUsecase: callingTestUsecase,
                isGroup: isGroup,
                isTeam: isTeam
            )
        }

    }

    func testGenerateCallNotification_It_Does_Not_Generate_Notification_When_Timed_Out() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam, isTimeout: true)
        let callingContent = setupCallingContentMock(type: "SETUP")

        var calling = Calling()
        calling.content = callingContent

        // When

        sut = ConversationCallingEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore,
                userDefaults: defaults
            ),
            accountID: .mockID1
        )

        let userNotification = await sut.buildContent(
            calling: calling,
            at: .now,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        // Then, not display calling notification because timed out
        XCTAssertNil(userNotification)
    }

    func testGenerateCallNotification_IsOneOnOne_Team_Should_Build_Notification_Returns_False() async {
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

        // When

        sut = ConversationCallingEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                conversationLocalStore: conversationLocalStore,
                userDefaults: defaults
            ),
            accountID: .mockID1
        )

        let userNotification = await sut.buildContent(
            calling: calling,
            at: .now,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        // Then
        XCTAssertNil(userNotification)
    }

    // MARK: - Internal tests assertion helpers

    private func internalCallKitTest_assertNotificationContent(
        testUsecase: CallKitTestUseCase,
        content: UserNotification,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {

        guard case let .callKit(callKitPayload) = content else {
            return XCTFail()
        }

        XCTAssertEqual(callKitPayload["accountID"] as! String, Scaffolding.accountID.uuidString)
        XCTAssertEqual(callKitPayload["conversationID"] as! String, Scaffolding.conversationID.id.uuidString)

        switch testUsecase {
        case .incomingAudioCall:
            XCTAssertEqual(callKitPayload["shouldRing"] as! Bool, true)
            XCTAssertEqual(callKitPayload["hasVideo"] as! Bool, false)
        case .incomingVideoCall:
            XCTAssertEqual(callKitPayload["shouldRing"] as! Bool, true)
            XCTAssertEqual(callKitPayload["hasVideo"] as! Bool, true)
        case .endingCall:
            XCTAssertEqual(callKitPayload["shouldRing"] as! Bool, false)
            XCTAssertEqual(callKitPayload["hasVideo"] as! Bool, false)
        }

        let callerName = if isGroup {
            isTeam ? "\(Scaffolding.conversationName) in \(Scaffolding.teamName)" :
                "\(Scaffolding.conversationName)"

        } else {
            isTeam ? "\(Scaffolding.senderName) in \(Scaffolding.teamName)" : "\(Scaffolding.senderName)"
        }

        XCTAssertEqual(callKitPayload["callerName"] as! String, callerName)

    }

    private func internalTest_assertNotificationContent(
        _ content: UserNotification,
        callingTestUsecase: CallingTestUseCase,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {
        guard case let .text(notificationContent) = content else {
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
            Scaffolding.conversationID.id.uuidString.lowercased()
        )

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! String, UUID.mockID1.uuidString)
        XCTAssertNil(notificationContent.userInfo["senderIDString"])
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! String, UUID.mockID2.uuidString)
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

    // MARK: - CallKit tests use cases

    private enum CallKitTestUseCase {
        case incomingAudioCall(String)
        case incomingVideoCall(String)
        case endingCall(String)

        var json: String {
            switch self {
            case let .incomingAudioCall(string):
                string
            case let .incomingVideoCall(string):
                string
            case let .endingCall(string):
                string
            }
        }
    }

    private func getCallKitTestUseCases() -> [CallKitTestUseCase] {
        let startAudioCallJson = setupCallingContentMock(type: "SETUP")
        let startVideoCallJson = setupCallingContentMock(type: "SETUP", isVideo: true)
        let endCallJson = setupCallingContentMock(type: "CANCEL")

        return [
            .incomingAudioCall(startAudioCallJson),
            .incomingVideoCall(startVideoCallJson),
            .endingCall(endCallJson)
        ]

    }

    // MARK: - Mocks

    private func setupMock(
        isGroup: Bool,
        isTeam: Bool,
        isTimeout: Bool = false
    ) async {

        defaults.set(true, forKey: "isAVSReady")
        defaults.set(true, forKey: "isCallKitAvailable")

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.conversationMutedMessageTypesIncludingAvailability_MockValue = .some(.none)
        conversationLocalStore.lastReadServerTimestamp_MockValue = .now
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = await context.perform { [self] in
            modelHelper.createUser(in: context)
        }
        conversationLocalStore.isConversationForcedReadOnly_MockValue = false
        conversationLocalStore.conversationNeedsBackendUpdate_MockValue = false
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
        conversationLocalStore.increaseUnreadCountFor_MockMethod = { _ in }
        conversationLocalStore.fetchServerTimeDelta_MockValue = isTimeout ? .oneHour : .oneSecond
    }

    private enum Scaffolding {

        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
        static let accountID = UUID.mockID10
    }

}
