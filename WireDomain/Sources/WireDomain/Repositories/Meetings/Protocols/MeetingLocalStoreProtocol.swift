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
import WireCallingDomain

// sourcery: AutoMockable
/// A local store dedicated to meetings.
/// The store uses the injected context to perform `CoreData` operations on meeting objects.
public protocol MeetingLocalStoreProtocol: Sendable {

    /// Fetches all locally stored meetings.
    ///
    /// - Returns: The stored meetings.

    func storedMeetings() async -> [Meeting]

    /// Stores a meeting locally, creating or updating it.
    ///
    /// - Parameter meeting: The meeting to store.

    func storeMeeting(_ meeting: Meeting) async

    /// Stores the given meetings and deletes all stored meetings not contained in the list.
    /// Use this when the given meetings are a full snapshot of the backend state.
    ///
    /// - Parameter meetings: The meetings to store.

    func replaceAllMeetings(with meetings: [Meeting]) async

    /// Deletes a locally stored meeting.
    ///
    /// - Parameter id: The qualified id of the meeting to delete.

    func deleteMeeting(id: QualifiedID) async

}
