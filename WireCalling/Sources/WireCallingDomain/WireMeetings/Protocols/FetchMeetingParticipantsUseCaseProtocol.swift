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
/// Fetches the current participants of a meeting's underlying conversation,
/// excluding the self user. The conversation is the source of truth for a
/// meeting's members; the backend's meeting responses don't include them.
package protocol FetchMeetingParticipantsUseCaseProtocol: Sendable {

    func invoke(conversationID: QualifiedID) async throws -> [MeetingMember]

}
