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

final class CallKitNotificationBuilderTests: XCTestCase {
    private var sut: CallKitNotificationBuilder!
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
        registerDependencies()
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

    private func registerDependencies() {
        Injector.register(ConversationLocalStoreProtocol.self) {
            self.conversationLocalStore
        }

        Injector.register(UserLocalStoreProtocol.self) {
            self.userLocalStore
        }
    }

    func testGenerateCallKitNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)
        let callKitTestUsecases = getCallKitTestUseCases()

        for callKitTestUsecase in callKitTestUsecases {
            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = await CallKitNotificationBuilder(
                calling: calling,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID,
                accountID: Scaffolding.accountID,
                userDefaults: defaults,
                callKitReporting: MockCallKitReporting.self
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            _ = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                callKitTestUsecase: callKitTestUsecase,
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
            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = await CallKitNotificationBuilder(
                calling: calling,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID,
                accountID: Scaffolding.accountID,
                userDefaults: defaults,
                callKitReporting: MockCallKitReporting.self
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            _ = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                callKitTestUsecase: callKitTestUsecase,
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
            var calling = Calling()
            calling.content = callKitTestUsecase.json

            sut = await CallKitNotificationBuilder(
                calling: calling,
                conversationID: Scaffolding.conversationID,
                senderID: Scaffolding.userID,
                accountID: Scaffolding.accountID,
                userDefaults: defaults,
                callKitReporting: MockCallKitReporting.self
            )

            let shouldBuildNotification = await sut.shouldBuildNotification()
            XCTAssertEqual(shouldBuildNotification, true)

            _ = await sut.buildContent()

            try await internalTest_assertNotificationContent(
                callKitTestUsecase: callKitTestUsecase,
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

        sut = await CallKitNotificationBuilder(
            calling: calling,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID,
            accountID: Scaffolding.accountID,
            userDefaults: defaults,
            callKitReporting: MockCallKitReporting.self
        )

        let shouldBuildNotification = await sut.shouldBuildNotification()
        XCTAssertEqual(shouldBuildNotification, false)
    }

    private func internalTest_assertNotificationContent(
        callKitTestUsecase: CallKitTestUseCase,
        isGroup: Bool,
        isTeam: Bool
    ) async throws {
        let callKitPayload = try XCTUnwrap(MockCallKitReporting.payload)

        XCTAssertEqual(callKitPayload["accountID"] as! String, Scaffolding.accountID.uuidString)
        XCTAssertEqual(callKitPayload["conversationID"] as! String, Scaffolding.conversationID.uuid.uuidString)

        switch callKitTestUsecase {
        case let .incomingAudioCall(string):
            XCTAssertEqual(callKitPayload["shouldRing"] as! Bool, true)
            XCTAssertEqual(callKitPayload["hasVideo"] as! Bool, false)
        case let .incomingVideoCall(string):
            XCTAssertEqual(callKitPayload["shouldRing"] as! Bool, true)
            XCTAssertEqual(callKitPayload["hasVideo"] as! Bool, true)
        case let .endingCall(string):
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

    // MARK: - Tested use cases

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

    struct MockCallKitReporting: CallKitReporting {
        nonisolated(unsafe) static var payload: [AnyHashable: Any]!

        static func reportIncomingCall(payload: [AnyHashable: Any]) async throws {
            Self.payload = payload
        }
    }

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

    private func setupMock(
        isGroup: Bool,
        isTeam: Bool
    ) async {

        defaults.set(true, forKey: "isAVSReady")
        defaults.set(true, forKey: "isCallKitAvailable")
        defaults.set([Scaffolding.accountID.uuidString], forKey: "loadedUserSessions")

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
    }

    private enum Scaffolding {

        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireAPI.QualifiedID(uuid: .mockID2, domain: "domain.com")
        static let userID = UserID(uuid: .mockID3, domain: "domain.com")
        static let accountID = UUID.mockID10
    }

}
