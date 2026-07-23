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

    /// Returns a stream that emits whenever meetings are created, updated or deleted,
    /// e.g. by processed sync events.
    ///
    /// The backend refresh performed by `fetchMeetings(in:offset:limit:)` does not emit,
    /// so observers can safely re-fetch in response to an emission without causing a loop.

    func observeMeetingChanges() -> AsyncStream<Void>

    func createMeeting(
        title: String,
        startTime: Date,
        endTime: Date,
        recurrence: MeetingRecurrence?
    ) async throws -> Meeting

    /// Stores a meeting locally without contacting the server, linking it to
    /// locally stored entities such as its conversation and creator.
    ///
    /// - Parameter meeting: The meeting to store.

    func storeMeeting(_ meeting: Meeting) async

    /// Pulls a meeting from the server and stores it locally.
    /// If the meeting no longer exists on the server, the locally stored copy is deleted.
    ///
    /// - Parameter id: The qualified id of the meeting to pull.
    /// - Returns: The pulled meeting, or `nil` if it no longer exists on the server.

    @discardableResult
    func pullMeeting(id: QualifiedID) async throws -> Meeting?

    /// Pulls all meetings from the server, replacing the locally stored
    /// meetings, e.g. as part of a sync.
    ///
    /// Does nothing if the backend does not support the meetings endpoint.

    func pullMeetings() async throws

    /// Deletes a locally stored meeting without contacting the server.
    ///
    /// - Parameter id: The qualified id of the meeting to delete.

    func deleteLocalMeeting(id: QualifiedID) async

    /// Deletes a meeting on the server and removes the locally stored copy.
    ///
    /// - Parameter id: The qualified id of the meeting to delete.

    func deleteMeeting(id: QualifiedID) async throws

    /// Fetches stored meetings whose start date lies in the given range,
    /// refreshing the local store from the backend first.
    ///
    /// - Parameters:
    ///   - range: The half-open range the meetings' start dates must lie in.
    ///   - offset: The number of matching meetings to skip, for pagination.
    ///   - limit: The maximum number of meetings to return.

    func fetchMeetings(in range: Range<Date>, offset: Int, limit: Int) async throws -> [Meeting]

    func hasUpcomingMeetings(after date: Date) async throws -> Bool

}
