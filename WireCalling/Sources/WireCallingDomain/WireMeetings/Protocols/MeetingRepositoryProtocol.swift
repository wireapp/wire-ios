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

public import Foundation

// sourcery: AutoMockable
/// Repository for accessing and managing meetings.
///
/// The protocol is implemented outside of this package, where the
/// persistence layer (Core Data) and the backend API are available,
/// and injected in.
public protocol MeetingRepositoryProtocol: Sendable {

    func fetchMeetingsStarting(after date: Date, offset: Int, limit: Int) -> [Meeting]

    /// Returns a stream that emits whenever meetings are created, updated or deleted,
    /// e.g. by processed sync events.
    ///
    /// The backend refresh performed by `fetchMeetingsStarting` does not emit, so
    /// observers can safely re-fetch in response to an emission without causing a loop.

    func observeMeetingChanges() -> AsyncStream<Void>

    func hasUpcomingMeetings(after date: Date) -> Bool

    func createMeeting(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    ) async throws -> Meeting

    /// Pulls a meeting from the server and stores it locally.
    /// If the meeting no longer exists on the server, the locally stored copy is deleted.
    ///
    /// - Parameter id: The qualified id of the meeting to pull.

    func pullMeeting(id: QualifiedID) async throws

    /// Pulls all meetings from the server, replacing the locally stored
    /// meetings, e.g. as part of a sync.
    ///
    /// Does nothing if the backend does not support the meetings endpoint.

    func pullMeetings() async throws

    /// Deletes a locally stored meeting without contacting the server.
    ///
    /// - Parameter id: The qualified id of the meeting to delete.

    func deleteLocalMeeting(id: QualifiedID) async

}
