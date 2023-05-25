//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// NOTE: Some legacy predicates tests already exist in `ZMConversationTests.m`

class ZMConversationTests_Predicates: ZMConversationTestsBase {
    func test_itReturnsMlsConversations_withMlsStatusReady() {
        syncMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.conversationType = .group
            conversation.messageProtocol = .mls
            conversation.mlsStatus = .ready

            // when
            let sut = ZMConversation.predicateForConversationsIncludingArchived()

            // then
            XCTAssertTrue(sut.evaluate(with: conversation))
        }
    }

    func test_itDoesntReturnMlsConversations_withMlsStatusNotReady() {
        syncMOC.performAndWait {
            // given
            let conversation = ZMConversation.insertNewObject(in: syncMOC)
            conversation.conversationType = .group
            conversation.messageProtocol = .mls
            conversation.mlsStatus = .pendingJoin

            // when
            let sut = ZMConversation.predicateForConversationsIncludingArchived()

            // then
            XCTAssertFalse(sut.evaluate(with: conversation))
        }
    }
}
