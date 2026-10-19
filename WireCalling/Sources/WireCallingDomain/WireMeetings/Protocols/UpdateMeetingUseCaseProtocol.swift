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

package import Foundation

// sourcery: AutoMockable
/// Updates an existing meeting via the backend API and adjusts the
/// participants of its conversation to match the given selection.
package protocol UpdateMeetingUseCaseProtocol: Sendable {

    /// - Parameters:
    ///   - meeting: The meeting to update, as it was before editing.
    ///     Its conversation's participants are the baseline for the
    ///     participant changes; if the conversation has not been resolved
    ///     from the local store, the update fails without changing anything.
    ///   - participants: The complete participant selection after editing;
    ///     members missing from it are removed from the conversation,
    ///     new ones are added.

    func invoke(
        meeting: Meeting,
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?,
        participants: [MeetingMember]
    ) async throws -> Meeting

    /// Updates the meeting's dedicated conversation name without updating the meeting itself.
    func updateConversationName(for meeting: Meeting) async throws

}
