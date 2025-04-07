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

import Foundation
import WireTestingPackage
import XCTest
@testable import Wire

final class ConversationDetailsTests: XCTestCase {

    lazy var conversation = {
        let conversation = MockGroupDetailsConversation()
        conversation.isChannel = true
        return conversation
    }()

    let user = {
        let user = MockUserType()
        user.canManageTeam = false
        user.isGroupAdminInConversation = false
        return user
    }()

    let sut = GroupOptionsSectionController.Option.channelAccess

    func testAccessOptionNotAllowedForGroup() {
        user.canManageTeam = true
        conversation.isChannel = false

        XCTAssertFalse(
            sut.accessible(in: conversation, by: user)
        )
    }

    func testAccessOptionAllowed_ForChannel_andTeamAdmin() {
        user.canManageTeam = true

        XCTAssertTrue(
            sut.accessible(in: conversation, by: user)
        )
    }

    func testAccessOptionNotAllowed_ForChannel_Member() {
        XCTAssertFalse(
            sut.accessible(in: conversation, by: user)
        )
    }

    func testAccessOptionAllowed_ForChannel_MemberButTeamOwner() {
        user.canManageTeam = true

        XCTAssertTrue(sut.accessible(in: conversation, by: user))
    }

    func testAccessOptionAllowed_ForChannel_ChannelOwner() {
        user.isGroupAdminInConversation = true

        XCTAssertTrue(sut.accessible(in: conversation, by: user))
    }
}
