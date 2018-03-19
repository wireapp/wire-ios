////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
@testable import WireMessageStrategy

class AssetRequestFactoryRetentionTests: MessagingTestBase {

    func testThatRegularUserInRegularConversationAssetsArePermanent() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let user = self.otherUser!
            let conversation = self.groupConversation!

            // then
            let retention = AssetRequestFactory.defaultAssetRetention(for: user, in: conversation)
            XCTAssertEqual(retention, .persistent)
        }
    }

    func testThatTeamUserInRegularConversationAssetsAreEternal() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let user = self.otherUser!
            let team = Team.insertNewObject(in: self.syncMOC)
            let member = Member.insertNewObject(in: self.syncMOC)
            member.user = user
            member.team = team

            let conversation = self.groupConversation!

            // then
            let retention = AssetRequestFactory.defaultAssetRetention(for: user, in: conversation)
            XCTAssertEqual(retention, .eternal)
        }
    }

    func testThatRegularUserInTeamConversationAssetsAreEternal() {
        self.syncMOC.performGroupedBlockAndWait {
            // given
            let user = self.otherUser!
            let conversation = self.groupConversation!
            conversation.team = Team.insertNewObject(in: self.syncMOC)

            // then
            let retention = AssetRequestFactory.defaultAssetRetention(for: user, in: conversation)
            XCTAssertEqual(retention, .eternal)
        }
    }
}

