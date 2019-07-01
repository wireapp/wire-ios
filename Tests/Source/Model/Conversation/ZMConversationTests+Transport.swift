//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

extension ZMConversationTransportTests {
    //final class ConversationTransportTests: ZMConversationTestsBase {
    func testThatItDoesNotUpdatesLastModifiedDateIfAlreadyExists() {
        syncMOC.performGroupedAndWait() {_ in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let uuid = UUID.create()
            conversation.remoteIdentifier = uuid
            let currentTime = Date()

            // assume that the backup date is one day before
            let lastModifiedDate = currentTime.addingTimeInterval(86400)
            conversation.lastModifiedDate = lastModifiedDate
            let serverTimestamp = currentTime

            let payload = self.payloadForMetaData(of: conversation, conversationType: .convTypeGroup, isArchived: true, archivedRef: currentTime, isSilenced: true, silencedRef: currentTime, silencedStatus: nil)

            // when
            conversation.update(withTransportData: payload, serverTimeStamp: serverTimestamp)

            // then
            XCTAssertEqual(conversation.lastServerTimeStamp, serverTimestamp)
            XCTAssertEqual(conversation.lastModifiedDate, lastModifiedDate)
            XCTAssertNotEqual(conversation.lastModifiedDate, serverTimestamp)
        }
    }
}
