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

import Foundation
import Testing
import WireDataModel
import WireSystem

@testable import WireDomain

struct BufferedMLSMessageRecoveryTrackerTests {

    private let groupID = MLSGroupID(Data("group-id".utf8))
    private let otherGroupID = MLSGroupID(Data("other-group-id".utf8))
    private let timestamp = Date(timeIntervalSince1970: 1_784_628_000)
    private let journal = Journal(userID: UUID(), storage: UserDefaults.temporary())

    @Test
    func `buffered messages exactly at threshold should not recover`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 60))
    }

    @Test
    func `buffered messages beyond threshold should recover`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 61))
    }

    @Test
    func `reverse ordered buffered messages beyond threshold should recover`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 120))
        #expect(sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
    }

    @Test
    func `different conversations and subconversations are tracked independently`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(
            !sut.observeBufferedMessage(groupID: otherGroupID, subconversation: nil, timestamp: timestamp + 120)
        )
        #expect(
            !sut.observeBufferedMessage(
                groupID: groupID,
                subconversation: "conference",
                timestamp: timestamp + 240
            )
        )
    }

    @Test
    func `clearing starts a new window`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        sut.clear(groupID: groupID, subconversation: nil)
        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 120))
    }

    @Test
    func `triggering recovery starts a new window`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 61))
        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 62))
        #expect(sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 123))
    }

    @Test
    func `tracking is shared across instances using the same journal`() {
        let firstPayloadTracker = BufferedMLSMessageRecoveryTracker(journal: journal)
        let secondPayloadTracker = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(
            !firstPayloadTracker.observeBufferedMessage(
                groupID: groupID,
                subconversation: nil,
                timestamp: timestamp
            )
        )
        #expect(
            secondPayloadTracker.observeBufferedMessage(
                groupID: groupID,
                subconversation: nil,
                timestamp: timestamp + 61
            )
        )
    }

    @Test
    func `clearing one conversation keeps tracking of others`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(!sut.observeBufferedMessage(groupID: otherGroupID, subconversation: nil, timestamp: timestamp))
        sut.clear(groupID: groupID, subconversation: nil)
        #expect(sut.observeBufferedMessage(groupID: otherGroupID, subconversation: nil, timestamp: timestamp + 61))
    }

    @Test
    func `undecodable stored tracking is reset`() {
        journal[.bufferedMLSMessageTimestampRanges] = Data("not json".utf8)
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 61))
    }

    @Test
    func `journal value is removed once nothing is tracked`() {
        let sut = BufferedMLSMessageRecoveryTracker(journal: journal)

        #expect(!sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(journal[.bufferedMLSMessageTimestampRanges] != nil)
        sut.clear(groupID: groupID, subconversation: nil)
        #expect(journal[.bufferedMLSMessageTimestampRanges] == nil)
    }

}
