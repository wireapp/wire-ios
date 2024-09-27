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

final class ConversationSystemMessageCellSnapshotTests: ConversationMessageSnapshotTestCase {
    // MARK: Internal

    // MARK: MLS Verification

    func test_mlsConversationVerified() {
        let message = makeMessage(messageType: .conversationIsVerified)
        verify(message: message)
    }

    func test_mlsConversationDegraded() {
        let message = makeMessage(messageType: .conversationIsDegraded)
        verify(message: message)
    }

    // MARK: MLS Migration

    func test_mlsMigrationFinalized() {
        let message = makeMessage(messageType: .mlsMigrationFinalized)
        verify(message: message)
    }

    func test_mlsMigrationJoinAfterwards() {
        let message = makeMessage(messageType: .mlsMigrationJoinAfterwards)
        verify(message: message)
    }

    func test_mlsMigrationOngoingCall() {
        let message = makeMessage(messageType: .mlsMigrationOngoingCall)
        verify(message: message)
    }

    func test_mlsMigrationStarted() {
        let message = makeMessage(messageType: .mlsMigrationStarted)
        verify(message: message)
    }

    func test_mlsMigrationUpdateVersion() {
        let message = makeMessage(messageType: .mlsMigrationUpdateVersion)
        verify(message: message)
    }

    func test_mlsMigrationPotentialGap() {
        let message = makeMessage(messageType: .mlsMigrationPotentialGap)
        verify(message: message)
    }

    // MARK: Private

    // MARK: - Helpers

    private func makeMessage(messageType: ZMSystemMessageType) -> MockMessage {
        MockMessageFactory.systemMessage(with: messageType)!
    }
}
