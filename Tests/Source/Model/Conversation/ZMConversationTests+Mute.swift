//
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

import Foundation
@testable import WireDataModel

extension ZMConversation {
    @objc var isFullyMuted: Bool {
        return mutedMessageTypes == .all
    }
    
    @objc var isOnlyMentions: Bool {
        return mutedMessageTypes == .nonMentions
    }
}

class ZMConversationTests_Mute : ZMConversationTestsBase {

    func testThatItDoesNotCountsSilencedConversationsUnreadContentAsUnread() {
        syncMOC.performGroupedAndWait { _ in
            // given
            XCTAssertEqual(ZMConversation.unreadConversationCount(in: self.syncMOC), 0)
            
            let conversation = self.insertConversation(withUnread: true)
            conversation?.mutedMessageTypes = .all
            
            // when
            XCTAssertTrue(self.syncMOC.saveOrRollback())
            
            // then
            XCTAssertEqual(ZMConversation.unreadConversationCountExcludingSilenced(in: self.syncMOC, excluding: nil), 0)

        }
    }
    
    func testThatTheConversationIsNotSilencedByDefault() {
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        // then
        XCTAssertEqual(conversation.mutedMessageTypes, .none)
    }

}
