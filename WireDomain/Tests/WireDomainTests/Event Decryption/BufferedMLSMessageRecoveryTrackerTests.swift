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

@testable import WireDomain

struct BufferedMLSMessageRecoveryTrackerTests {

    private let groupID = MLSGroupID(Data("group-id".utf8))
    private let otherGroupID = MLSGroupID(Data("other-group-id".utf8))
    private let timestamp = Date(timeIntervalSince1970: 1_784_628_000)

    @Test
    func `buffered messages exactly at threshold should not recover`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 60))
    }

    @Test
    func `buffered messages beyond threshold should recover`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(await sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 61))
    }

    @Test
    func `reverse ordered buffered messages beyond threshold should recover`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 120))
        #expect(await sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
    }

    @Test
    func `different conversations and subconversations are tracked independently`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(
            await !sut.observeBufferedMessage(groupID: otherGroupID, subconversation: nil, timestamp: timestamp + 120)
        )
        #expect(
            await !sut.observeBufferedMessage(
                groupID: groupID,
                subconversation: "conference",
                timestamp: timestamp + 240
            )
        )
    }

    @Test
    func `clearing starts a new window`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        await sut.clear(groupID: groupID, subconversation: nil)
        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 120))
    }

    @Test
    func `triggering recovery starts a new window`() async {
        let sut = BufferedMLSMessageRecoveryTracker()

        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp))
        #expect(await sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 61))
        #expect(await !sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 62))
        #expect(await sut.observeBufferedMessage(groupID: groupID, subconversation: nil, timestamp: timestamp + 123))
    }

}
