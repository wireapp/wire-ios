//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import Foundation
import XCTest
@testable import Wire
import WireTesting

class ActiveCallRouterTests: ZMTestCase {

    var sut: ActiveCallRouter!

    override func setUp() {
        super.setUp()
        sut = ActiveCallRouter(rootviewController: RootViewController())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThat_ItExecutesPostCallAction_IfActiveCall_IsNotShown() {
        // given
        sut.isActiveCallShown = false
        var executed = false

        // when
        sut.executeOrSchedulePostCallAction {
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
        sut.executeOrSchedulePostCallAction {
            executed = true
        }

        // then
        XCTAssertNotNil(sut.scheduledPostCallAction)
        XCTAssertFalse(executed)
        sut.scheduledPostCallAction?()
        XCTAssertTrue(executed)
    }

    func testThat_ItSetIsActiveCallShown_ToFalse_When_RestoringCallFromTopOverlay() {
        // given
        let conversation = ((MockConversation.oneOnOneConversation() as Any) as! ZMConversation)
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

}
