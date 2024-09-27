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

import XCTest
@testable import Wire

final class ActiveCallRouterTests: ZMSnapshotTestCase {
    // MARK: Internal

    var mockTopOverlayPresenter: MockTopOverlayPresenting!
    var sut: ActiveCallRouter<MockTopOverlayPresenting>!
    var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()

        mockTopOverlayPresenter = .init()
        userSession = UserSessionMock()
        sut = ActiveCallRouter(
            mainWindow: .init(),
            userSession: userSession,
            topOverlayPresenter: mockTopOverlayPresenter
        )
    }

    override func tearDown() {
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
        sut.scheduledPostCallAction?({})
        XCTAssertTrue(executed)
    }

    func testThat_ItSetIsActiveCallShown_ToFalse_When_RestoringCallFromTopOverlay() {
        // given
        let conversation = createOneOnOneConversation()
        let voiceChannel = MockVoiceChannel(conversation: conversation)
        let mockSelfClient = MockUserClient()
        mockSelfClient.remoteIdentifier = "selfClient123"
        MockUser.mockSelf().clients = Set([mockSelfClient])

        sut.isActiveCallShown = true

        // when
        sut.voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: voiceChannel)

        // then
        XCTAssertFalse(sut.isActiveCallShown)
    }

    // MARK: Private

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
