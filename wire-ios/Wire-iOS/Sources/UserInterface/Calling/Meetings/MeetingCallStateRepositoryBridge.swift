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

import WireCallingDomain
import WireDataModel
import WireFoundation
import WireSyncEngine

/// Bridges `WireSyncEngine`'s call state into `WireCallingDomain`'s
/// `MeetingCallStateRepositoryProtocol`, so the meetings feature can tell which
/// meetings the self user is currently attending (in a call in) without
/// depending on `WireSyncEngine` directly.
final class MeetingCallStateRepositoryBridge: MeetingCallStateRepositoryProtocol, @unchecked Sendable {

    private let userSession: any UserSession

    init(userSession: any UserSession) {
        self.userSession = userSession
    }

    func observeAttendedConversations() -> AsyncStream<Set<WireCallingDomain.QualifiedID>> {
        AsyncStream { continuation in
            let observer = CallStateChangeObserver { [weak self] in
                continuation.yield(self?.currentAttendedConversationIDs() ?? [])
            }
            let token = userSession.addConferenceCallStateObserver(observer)

            // Emit the current value straight away so the UI is correct before the first change.
            continuation.yield(currentAttendedConversationIDs())

            // Keep the observer and its registration token alive for the stream's lifetime.
            continuation.onTermination = { _ in
                withExtendedLifetime((observer, token)) {}
            }
        }
    }

    /// The conversation ids of the calls the self user is currently in (joined, answered or outgoing).
    private func currentAttendedConversationIDs() -> Set<WireCallingDomain.QualifiedID> {
        guard
            let session = userSession as? ZMUserSession,
            let callCenter = session.callCenter
        else {
            return []
        }

        let conversations = callCenter.activeCallConversations(in: session)
        return Set(conversations.compactMap { conversation -> WireCallingDomain.QualifiedID? in
            guard let qualifiedID = conversation.qualifiedID else { return nil }
            return WireCallingDomain.QualifiedID(id: qualifiedID.uuid, domain: qualifiedID.domain)
        })
    }

}

/// Small adapter that turns the delegate-style call-state callback into a closure.
private final class CallStateChangeObserver: WireCallCenterCallStateObserver {

    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        onChange()
    }

}
