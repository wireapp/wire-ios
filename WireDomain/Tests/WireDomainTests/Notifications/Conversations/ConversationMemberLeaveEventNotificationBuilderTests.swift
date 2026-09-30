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

import WireCallingData
import WireCallingDomain
import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationMemberLeaveEventNotificationBuilderTests: XCTestCase {
    private var sut: ConversationMemberLeaveEventNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var featureStore: MockFeatureConfigLocalStoreProtocol!
    private var conversationsAPI: MockConversationsAPI!
    private var meetingStore: MeetingStoreSpy!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        featureStore = MockFeatureConfigLocalStoreProtocol()
        conversationsAPI = MockConversationsAPI()
        meetingStore = MeetingStoreSpy()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        conversationLocalStore = nil
        userLocalStore = nil
        featureStore = nil
        conversationsAPI = nil
        meetingStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    func testGenerateConversationMemberLeaveEventNotification_Is_Group_Conversation_And_Is_Team_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        sut = ConversationMemberLeaveEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(userLocalStore: userLocalStore)
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserRemovedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )

    }

    func testGenerateConversationMemberLeaveEventNotification_Is_Group_Conversation_And_Is_Personal_User() async throws {

        // Mock

        let isGroup = true
        let isTeam = false

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        sut = ConversationMemberLeaveEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(userLocalStore: userLocalStore)
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserRemovedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )
    }

    func testGenerateConversationMemberLeaveEventNotification_Is_OneOnOne_Conversation_And_Team() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        sut = ConversationMemberLeaveEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(userLocalStore: userLocalStore)
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.selfUserRemovedEvent)

        // Then
        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isGroup: isGroup,
            isTeam: isTeam
        )

    }

    func testGenerateConversationMemberLeaveEventNotification_It_Should_Not_Build_Notification() async throws {

        // Mock

        let isGroup = false
        let isTeam = true

        await setupMock(isGroup: isGroup, isTeam: isTeam)

        sut = ConversationMemberLeaveEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore
            ),
            validator: .init(userLocalStore: userLocalStore)
        )

        // When
        let userNotification = await sut.buildContent(event: Scaffolding.otherUserRemovedEvent)

        // Then
        XCTAssertNil(userNotification)
    }

    func testGenerateMeetingCancellationNotification_WhenSelfUserIsRemovedFromMeetingByOtherUser() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = true
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        try assertMeetingCancellationNotification(try XCTUnwrap(userNotification))
    }

    func testGenerateMeetingCancellationNotification_WhenLocalMeetingConversationHasNoName() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = true
        conversationLocalStore.nameFor_MockValue = .some(nil)
        meetingStore.meetings = [Scaffolding.meeting]
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore, meetingLocalStore: meetingStore)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        try assertMeetingCancellationNotification(try XCTUnwrap(userNotification))
    }

    func testGenerateMeetingCancellationNotification_WhenMeetingConversationOnlyExistsRemotely() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = false
        conversationLocalStore.conversationNeedsBackendUpdate_MockValue = true
        conversationLocalStore.nameFor_MockValue = .some(nil)
        conversationsAPI.getConversationsFor_MockValue = .init(
            found: [.init(name: Scaffolding.conversationName, groupType: .meeting)],
            notFound: [],
            failed: []
        )
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore, conversationsAPI: conversationsAPI)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        try assertMeetingCancellationNotification(try XCTUnwrap(userNotification))
        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations, [[Scaffolding.conversationID]])
    }

    func testGenerateMeetingCancellationNotification_WhenStoredMeetingMatchesConversation() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        meetingStore.meetings = [Scaffolding.meeting]
        conversationLocalStore.isMeetingConversation_MockValue = false
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore, meetingLocalStore: meetingStore)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        try assertMeetingCancellationNotification(try XCTUnwrap(userNotification))
        XCTAssertTrue(conversationsAPI.getConversationsFor_Invocations.isEmpty)
    }

    func testGenerateMeetingCancellationNotification_WhenStaleConversationCannotBeResolvedRemotely() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = false
        conversationLocalStore.conversationNeedsBackendUpdate_MockValue = true
        conversationLocalStore.nameFor_MockValue = .some(nil)
        conversationsAPI.getConversationsFor_MockValue = .init(
            found: [],
            notFound: [Scaffolding.conversationID],
            failed: []
        )
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore, conversationsAPI: conversationsAPI)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        XCTAssertNil(userNotification)
        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations, [[Scaffolding.conversationID]])
    }

    func testGenerateMeetingCancellationNotification_WhenRemoteConversationIsNotMeeting() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = false
        conversationLocalStore.conversationNeedsBackendUpdate_MockValue = true
        conversationsAPI.getConversationsFor_MockValue = .init(
            found: [.init(groupType: .group)],
            notFound: [],
            failed: []
        )
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore, conversationsAPI: conversationsAPI)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        XCTAssertNil(userNotification)
        XCTAssertEqual(conversationsAPI.getConversationsFor_Invocations, [[Scaffolding.conversationID]])
    }

    func testGenerateMeetingCancellationNotification_WhenSelfUserRemovedThemselves() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = true
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: true
        )
        sut = makeSUT(featureConfigLocalStore: featureStore)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        XCTAssertNil(userNotification)
    }

    func testGenerateMeetingCancellationNotification_WhenConversationIsNotMeeting() async throws {
        await setupMock(isGroup: true, isTeam: true)
        await setupMeetingsFeature(isEnabled: true)
        conversationLocalStore.isMeetingConversation_MockValue = false
        userLocalStore.isSelfUserIdDomain_MockValue = (
            user: userLocalStore.fetchSelfUser_MockValue!,
            isSelfUser: false
        )
        sut = makeSUT(featureConfigLocalStore: featureStore)

        let userNotification = await sut.buildMeetingCancellationContent(event: Scaffolding.selfUserRemovedEvent)

        XCTAssertNil(userNotification)
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
            "\(Scaffolding.senderName) removed you"
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

    private func assertMeetingCancellationNotification(
        _ userNotification: UserNotification,
        title: String = Scaffolding.conversationName
    ) throws {
        guard case let .text(notificationContent) = userNotification else {
            return XCTFail()
        }

        XCTAssertEqual(notificationContent.title, title)
        XCTAssertEqual(
            notificationContent.body,
            String.formated(
                key: "push.notification.body.senderCanceledMeeting",
                bundle: .module,
                Scaffolding.senderName
            )
        )
        XCTAssertEqual(notificationContent.categoryIdentifier, NotificationCategory.meetingCancellation.rawValue)
        XCTAssertEqual(notificationContent.sound, .default)
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! String, Scaffolding.selfUserID.uuidString)
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
            modelHelper.createSelfUser(id: Scaffolding.selfUserID, in: context)
        }
        conversationLocalStore.isConversationForcedReadOnly_MockValue = false
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        userLocalStore.idFor_MockValue = Scaffolding.selfUserID
        userLocalStore.teamNameFor_MockValue = .some(isTeam ? Scaffolding.teamName : nil)
        conversationLocalStore.shouldHideNotification_MockValue = false
        conversationLocalStore.decreaseUnreadCountFor_MockMethod = { _ in }
    }

    private func setupMeetingsFeature(isEnabled: Bool) async {
        featureStore.fetchFeatureName_MockValue = await context.perform { [self] in
            Feature.updateOrCreate(havingName: .meetings, in: context) { feature in
                feature.status = isEnabled ? .enabled : .disabled
            }
            return Feature.fetch(name: .meetings, context: context)
        }
        featureStore.isFeatureEnabled_ReturnValue = isEnabled
    }

    private func makeSUT(
        featureConfigLocalStore: (any FeatureConfigLocalStoreProtocol)? = nil,
        conversationsAPI: (any ConversationsAPI)? = nil,
        meetingLocalStore: (any MeetingLocalStoreProtocol)? = nil
    ) -> ConversationMemberLeaveEventNotificationBuilder {
        ConversationMemberLeaveEventNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore,
                conversationsAPI: conversationsAPI,
                meetingLocalStore: meetingLocalStore
            ),
            validator: .init(
                userLocalStore: userLocalStore,
                featureConfigLocalStore: featureConfigLocalStore
            )
        )
    }

    private enum Scaffolding {
        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
        static let selfUserID = UUID.mockID1
        static let meeting = Meeting(
            id: WireCallingDomain.QualifiedID(id: .mockID5, domain: "domain.com"),
            title: conversationName,
            start: .now,
            end: .now.addingTimeInterval(3600),
            recurrence: nil,
            conversationID: WireCallingDomain.QualifiedID(id: conversationID.id, domain: conversationID.domain),
            creatorID: WireCallingDomain.QualifiedID(id: userID.id, domain: userID.domain)
        )

        static let selfUserRemovedEvent = ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: userID, // self user was removed, notification will be processed
            timestamp: .now,
            removedUserIDs: [.init(id: selfUserID, domain: "")],
            reason: .userRemoved
        )

        static let otherUserRemovedEvent = ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: userID, // self user was not removed, notification will NOT be processed
            timestamp: .now,
            removedUserIDs: [.init(id: .mockID4, domain: "")],
            reason: .userRemoved
        )
    }

}

private final class MeetingStoreSpy: MeetingLocalStoreProtocol, @unchecked Sendable {

    var meetings: [Meeting] = []

    func storedMeetings() async -> [Meeting] {
        meetings
    }

    func storedMeeting(id: WireCallingDomain.QualifiedID) async -> Meeting? {
        meetings.first { $0.id == id }
    }

    func storeMeeting(_ meeting: Meeting) async {
        meetings.append(meeting)
    }

    func replaceAllMeetings(with meetings: [Meeting]) async {
        self.meetings = meetings
    }

    func deleteMeeting(id: WireCallingDomain.QualifiedID) async {
        meetings.removeAll { $0.id == id }
    }

}
