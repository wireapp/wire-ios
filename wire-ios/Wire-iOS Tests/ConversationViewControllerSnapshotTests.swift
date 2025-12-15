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

import WireMessagingDomainSupport
import WireSyncEngineSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ConversationViewControllerSnapshotTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {

    private var mockMainCoordinator: AnyMainCoordinator!
    private var sut: ConversationViewController!
    private var serviceUser: ZMUser!
    private var userSession: UserSessionMock!
    var coreDataFixture: CoreDataFixture!
    var snapshotHelper: SnapshotHelper!

    override func setupCoreDataStack() async throws {
        coreDataFixture = try await CoreDataFixture()
        coreDataStack = coreDataFixture.coreDataStack
        uiMOC = coreDataFixture.coreDataStack.viewContext
    }

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        mockMainCoordinator = .init(mainCoordinator: MockMainCoordinator())
    }

    override func setUp() {
        super.setUp()

        snapshotHelper = SnapshotHelper()
        serviceUser = coreDataFixture.createServiceUser()
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        serviceUser = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func testForInitState() {
        // given
        let mockConversation = createTeamGroupConversation()
        createSut(conversation: mockConversation)

        // then
        snapshotHelper.verify(matching: sut)
    }
}

// MARK: - Disable / Enable search in conversations

extension ConversationViewControllerSnapshotTests {

    func testThatTheSearchButtonIsDisabledIfMessagesAreEncryptedInTheDataBase() {
        // given
        let mockConversation = createTeamGroupConversation()
        createSut(conversation: mockConversation)

        // when
        userSession.encryptMessagesAtRest = true

        // then
        XCTAssertFalse(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsEnabledIfMessagesAreNotEncryptedInTheDataBase() {
        // given
        let mockConversation = createTeamGroupConversation()
        createSut(conversation: mockConversation)

        // when
        userSession.encryptMessagesAtRest = false

        // then
        XCTAssertTrue(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsDisabled_IfConversationIsPendingConnection() {
        // given
        let mockConversation = createOneOnOneConversation(.pending)
        createSut(conversation: mockConversation)

        // then
        XCTAssertFalse(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsDisabled_IfConversationIsSentConnection() {
        // given
        let mockConversation = createOneOnOneConversation(.sent)
        createSut(conversation: mockConversation)

        // then
        XCTAssertFalse(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsEnabled_IfConversationIsOneOnOne() {
        // given
        let mockConversation = createOneOnOneConversation(.accepted)
        createSut(conversation: mockConversation)

        // then
        XCTAssertTrue(sut.shouldShowCollectionsButton)
    }

}

// MARK: - Guests bar controller

extension ConversationViewControllerSnapshotTests {

    func testThatGuestsBarControllerIsVisibleIfExternalsArePresent() {
        // given
        let mockConversation = createTeamGroupConversation()
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)
        UIColor.setAccentOverride(.green)
        createSut(conversation: mockConversation)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfServicesArePresent() {
        // given
        let mockConversation = createTeamGroupConversation()
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.addParticipantAndUpdateConversationState(user: serviceUser)

        UIColor.setAccentOverride(.green)
        createSut(conversation: mockConversation)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfExternalsAndServicesArePresent() {
        // given
        let mockConversation = createTeamGroupConversation()
        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)

        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.addParticipantAndUpdateConversationState(user: serviceUser)

        UIColor.setAccentOverride(.green)
        createSut(conversation: mockConversation)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Helper Method

    private func createSut(conversation: ZMConversation) {
        userSession = UserSessionMock(mockUser: .createSelfUser(name: "Bob"))
        userSession.coreDataStack = coreDataStack
        userSession.mockConversationList = ConversationList(
            allConversations: [conversation],
            filteringPredicate: NSPredicate(value: true),
            managedObjectContext: uiMOC,
            description: "all conversations"
        )
        userSession.coreDataStack?.newBackgroundContextProvider = { [uiMOC] in
            uiMOC!
        }

        sut = ConversationViewController(
            conversation: conversation,
            visibleMessage: nil,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            selfProfileUIBuilder: MockSelfProfileViewControllerBuilderProtocol(),
            conversationCreationRepository: MockConversationCreationRepositoryProtocol(),
            mediaPlaybackManager: .init(name: nil, userSession: userSession),
            classificationProvider: nil,
            networkStatusObservable: MockNetworkStatusObservable(),
            getParticipantImageSourceUseCase: MockGetParticipantImageSourceUseCaseProtocol(),
            wireMessagingFactory: MockWireMessagingFactoryProtocol.makeDefault()
        )
    }

    private func createOneOnOneConversation(_ connectionStatus: ZMConnectionStatus) -> ZMConversation {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID()
        otherUser.name = "Bruno"

        let mockConversation = ZMConversation.insertNewObject(in: uiMOC)
        mockConversation.messageProtocol = .proteus
        mockConversation.addParticipantAndUpdateConversationState(user: selfUser)
        mockConversation.conversationType = .oneOnOne
        mockConversation.remoteIdentifier = UUID.create()
        mockConversation.oneOnOneUser = otherUser

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = otherUser
        connection.status = connectionStatus

        return mockConversation
    }

}
