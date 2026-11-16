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

import XCTest

@testable import Wire

final class ActiveCallRouterTests: ZMSnapshotTestCase {

    var mockTopOverlayPresenter: MockTopOverlayPresenting!
    var sut: ActiveCallRouter<MockTopOverlayPresenting>!
    var userSession: UserSessionMock!
    var mainWindow: UIWindow!
    var rootViewController: RootPresentSpyViewController!

    override func setUp() {
        super.setUp()

        mockTopOverlayPresenter = .init()
        mockTopOverlayPresenter.dismissTopOverlayAnimated_MockMethod = { _ in }
        userSession = UserSessionMock()
        mainWindow = UIWindow()
        rootViewController = RootPresentSpyViewController()
        mainWindow.rootViewController = rootViewController
        sut = ActiveCallRouter(
            mainWindow: mainWindow,
            userSession: userSession,
            topOverlayPresenter: mockTopOverlayPresenter
        )
    }

    override func tearDown() {
        rootViewController = nil
        mainWindow = nil
        userSession = nil
        sut = nil
        mockTopOverlayPresenter = nil

        super.tearDown()
    }

    func testThat_ItExecutesPostCallAction_IfActiveCall_IsNotShown() {
        // given
        sut.isActiveCallShown = false
        var executed = false

        // when
        sut.executeOrSchedulePostCallAction { _ in
            executed = true
        }

        // then
        XCTAssertTrue(executed)
        XCTAssertNil(sut.scheduledPostCallAction)
    }

    func testThat_ItSavesPostCallAction_IfActiveCall_IsShown() {
        // given
        sut.isActiveCallShown = true
        var executed = false

        // when
        sut.executeOrSchedulePostCallAction { _ in
            executed = true
        }

        // then
        XCTAssertNotNil(sut.scheduledPostCallAction)
        XCTAssertFalse(executed)
        sut.scheduledPostCallAction? {}
        XCTAssertTrue(executed)
    }

    func testThat_ItSetIsActiveCallShown_ToTrue_When_RestoringCallFromTopOverlay() {
        // given
        let conversation = createOneOnOneConversation()
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        sut.isActiveCallShown = false

        // when
        sut.voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: voiceChannel)

        // then
        XCTAssertTrue(sut.isActiveCallShown)
    }

    func testThat_ItRepresentsCall_WhenStateSaysShown_ButNoPresentedCallVCExists() {
        // given (stale state)
        let conversation = createOneOnOneConversation()
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        let selfClient = MockUserClient()
        selfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([selfClient])

        sut.isActiveCallShown = true
        sut.isPresentingActiveCall = true
        XCTAssertNil(mainWindow.rootViewController?.presentedViewController)

        // when
        sut.presentActiveCall(for: voiceChannel, animated: false)

        // then
        XCTAssertEqual(rootViewController.presentCallCount, 1)
    }

    func testThat_ItDoesNotPresentAgain_WhenAlreadyPresentingAndNotStale() {
        // given
        let conversation = createOneOnOneConversation()
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        let selfClient = MockUserClient()
        selfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([selfClient])

        sut.isPresentingActiveCall = true
        sut.isActiveCallShown = false

        // when
        sut.presentActiveCall(for: voiceChannel, animated: false)

        // then
        XCTAssertEqual(rootViewController.presentCallCount, 0)
    }

    func testThat_ItShowsCallTopOverlayAgain_AfterRootReplacement() {
        // given
        let conversation = createOneOnOneConversation()
        var events: [String] = []
        mockTopOverlayPresenter.presentTopOverlayAnimated_MockMethod = { _, _ in events.append("present") }
        mockTopOverlayPresenter.dismissTopOverlayAnimated_MockMethod = { animated in
            XCTAssertFalse(animated)
            events.append("dismiss")
        }
        sut.showCallTopOverlay(for: conversation)
        sut.showCallTopOverlay(for: conversation)

        // when
        sut.prepareForRootReplacement()
        sut.showCallTopOverlay(for: conversation)

        // then
        XCTAssertEqual(events, ["present", "dismiss", "present"])
    }

    func testThat_ItKeepsRestoredCall_WhenEarlierDismissalCompletes() throws {
        // given
        let voiceChannel = MockVoiceChannel(conversation: createOneOnOneConversation())
        let selfClient = MockUserClient()
        selfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([selfClient])
        sut.presentActiveCall(for: voiceChannel, animated: false)
        let dismissed = try XCTUnwrap(rootViewController.presentedCallViewController)
        sut.prepareForRootReplacement()
        sut.presentActiveCall(for: voiceChannel, animated: false)
        let restored = try XCTUnwrap(rootViewController.presentedCallViewController)
        var actionCount = 0
        var completionCount = 0
        sut.executeOrSchedulePostCallAction { completion in
            actionCount += 1
            completion()
        }

        // when
        sut.activeCallDidDismiss(dismissed) { completionCount += 1 }

        // then
        XCTAssertTrue(sut.isActiveCallShown)
        XCTAssertNotNil(sut.scheduledPostCallAction)
        XCTAssertEqual(actionCount, 0)
        XCTAssertEqual(completionCount, 1)

        sut.activeCallDidDismiss(restored, completion: nil)
        XCTAssertFalse(sut.isActiveCallShown)
        XCTAssertNil(sut.scheduledPostCallAction)
        XCTAssertEqual(actionCount, 1)
    }

    func testThat_ItDeliversPostCallAction_AfterRootResetWithNoController() {
        // given
        sut.isActiveCallShown = true
        var actionCount = 0
        var completionCount = 0
        sut.executeOrSchedulePostCallAction { completion in
            actionCount += 1
            completion()
        }
        sut.prepareForRootReplacement()

        // when
        sut.dismissActiveCall(animated: false) { completionCount += 1 }
        sut.dismissActiveCall(animated: false, completion: nil)

        // then
        XCTAssertEqual(actionCount, 1)
        XCTAssertEqual(completionCount, 1)
        XCTAssertNil(sut.scheduledPostCallAction)
    }

    private func createOneOnOneConversation() -> ZMConversation {

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
        connection.status = .accepted

        return mockConversation
    }
}

final class RootPresentSpyViewController: UIViewController {

    var presentCallCount = 0
    var presentedCallViewController: UIViewController?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentCallCount += 1
        presentedCallViewController = viewControllerToPresent
        completion?()
    }
}
