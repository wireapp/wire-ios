//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class ConversationTests: ZMConversationTestsBase {
    func testThatItFindsConversationWithQueryStringWithTrailingSpace() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.userDefinedName = "Sömëbodÿ"
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        uiMOC.saveOrRollback()
        let _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        
        // when
        
        let request = ZMConversation.sortedFetchRequest(with: ZMConversation.predicate(forSearchQuery: "Sømebôdy ", selfUser: selfUser))
        let result = uiMOC.executeFetchRequestOrAssert(request)
        
        // then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?.first as? ZMConversation, conversation)
    }
}
