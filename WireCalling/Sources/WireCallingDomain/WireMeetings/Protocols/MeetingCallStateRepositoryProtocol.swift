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

// sourcery: AutoMockable
/// Reports which conversations the self user is currently in a call in, and lets
/// the meetings feature enter a meeting's call.
public protocol MeetingCallStateRepositoryProtocol: Sendable {

    /// Emits the set of conversation ids the self user is currently in a call in.
    ///
    /// The stream emits the current value immediately and then a new value
    /// whenever call state changes, so a meeting is considered "attending" while
    /// its `conversationID` is contained in the latest emitted set.
    func observeAttendedConversations() -> AsyncStream<Set<QualifiedID>>

    /// Enters the conversation's call: starts the conference when nobody is in it
    /// yet, and joins the running one otherwise.
    ///
    /// Returns once the join has been requested. The call UI is presented by the
    /// app's call state observer, not by the caller.
    func joinCall(in conversationID: QualifiedID) async throws

}
