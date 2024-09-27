//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import SnapshotTesting
import WireSyncEngineSupport
import WireTestingPackage
import XCTest
@testable import Wire

// MARK: - ConversationViewControllerSnapshotTests

final class ConversationViewControllerSnapshotTests: ZMSnapshotTestCase, CoreDataFixtureTestHelper {
    private var mockMainCoordinator: MockMainCoordinator!
    private var sut: ConversationViewController!
    private var mockConversation: ZMConversation!
    private var serviceUser: ZMUser!
    private var userSession: UserSessionMock!
    var coreDataFixture: CoreDataFixture!
    var snapshotHelper: SnapshotHelper!
    private var imageTransformerMock: MockImageTransformer!

    override func setupCoreDataStack() {
        coreDataFixture = CoreDataFixture()
        coreDataStack = coreDataFixture.coreDataStack
        uiMOC = coreDataFixture.coreDataStack.viewContext
    }

    override func setUp() {
        super.setUp()
        mockMainCoordinator = .init()
        snapshotHelper = SnapshotHelper()
        imageTransformerMock = .init()
        mockConversation = createTeamGroupConversation()
        userSession = UserSessionMock(mockUser: .createSelfUser(name: "Bob"))
        userSession.coreDataStack = coreDataStack
        userSession.mockConversationList = ConversationList(
            allConversations: [mockConversation!],
            filteringPredicate: NSPredicate(value: true),
            managedObjectContext: uiMOC,
            description: "all conversations"
        )

        serviceUser = coreDataFixture.createServiceUser()

        let mockAccount = Account(userName: "mock user", userIdentifier: UUID())
        let zClientViewController = ZClientViewController(account: mockAccount, userSession: userSession)

        sut = ConversationViewController(
            conversation: mockConversation,
            visibleMessage: nil,
            userSession: userSession,
            mainCoordinator: mockMainCoordinator,
            mediaPlaybackManager: .init(name: nil, userSession: userSession),
            classificationProvider: nil,
            networkStatusObservable: MockNetworkStatusObservable()
        )
    }

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        serviceUser = nil
        coreDataFixture = nil
        imageTransformerMock = nil
        mockMainCoordinator = nil

        super.tearDown()
    }

    func testForInitState() {
        snapshotHelper.verify(matching: sut)
    }
}

// MARK: - Disable / Enable search in conversations

extension ConversationViewControllerSnapshotTests {
    func testThatTheSearchButtonIsDisabledIfMessagesAreEncryptedInTheDataBase() {
        // given

        // when
        userSession.encryptMessagesAtRest = true

        // then
        XCTAssertFalse(sut.shouldShowCollectionsButton)
    }

    func testThatTheSearchButtonIsEnabledIfMessagesAreNotEncryptedInTheDataBase() {
        // given

        // when
        userSession.encryptMessagesAtRest = false

        // then
        XCTAssertTrue(sut.shouldShowCollectionsButton)
    }
}

// MARK: - Guests bar controller

extension ConversationViewControllerSnapshotTests {
    func testThatGuestsBarControllerIsVisibleIfExternalsArePresent() {
        // given
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)
        UIColor.setAccentOverride(.green)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfServicesArePresent() {
        // given
        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.addParticipantAndUpdateConversationState(user: serviceUser)

        UIColor.setAccentOverride(.green)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }

    func testThatGuestsBarControllerIsVisibleIfExternalsAndServicesArePresent() {
        // given
        let teamMember = Member.insertNewObject(in: uiMOC)
        teamMember.user = otherUser
        teamMember.team = team
        otherUser.membership?.setTeamRole(.partner)

        mockConversation.teamRemoteIdentifier = team?.remoteIdentifier
        mockConversation.addParticipantAndUpdateConversationState(user: serviceUser)

        UIColor.setAccentOverride(.green)

        // when
        sut.updateGuestsBarVisibility()

        // then
        snapshotHelper.verify(matching: sut)
    }
}
