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
@testable import WireDomain

final class MockAVSCallingEventService: AVSCallingEventServiceProtocol {

    var onIncomingCall: ((_ conversationId: String, _ userId: String, _ shouldRing: Bool, _ isVideoCall: Bool) -> Void)?
    var onMissedCall: ((_ conversationId: String, _ messageTime: Date, _ isVideoCall: Bool) -> Void)?
    var onCallClosed: ((_ reason: CallClosedReason, _ conversationId: String) -> Void)?

    private(set) var startCallCount = 0
    private(set) var endCallCount = 0
    private(set) var processInvocations: [(conversationId: String, userId: String)] = []

    func start() {
        startCallCount += 1
    }

    func process(
        data: Data,
        currentTime: UInt32,
        serverTime: UInt32,
        conversationId: String,
        userId: String,
        clientId: String,
        conversationType: Int32
    ) {
        processInvocations.append((conversationId: conversationId, userId: userId))
    }

    func end() {
        endCallCount += 1
    }
}
