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
/// An API access object for endpoints concerning meetings.
public protocol MeetingsAPI: Sendable {

    /// Fetch all meetings for the authenticated user.
    ///
    /// - Returns: The list of meetings.

    func listMeetings() async throws -> [MeetingResponse]

    /// Create a new meeting.
    ///
    /// - Parameter parameters: The meeting creation parameters.
    /// - Returns: The created meeting.

    func createMeeting(parameters: CreateMeetingParameters) async throws -> MeetingResponse

    /// Update an existing meeting.
    ///
    /// - Parameters:
    ///   - id: The id of the meeting to update.
    ///   - parameters: The meeting update parameters.
    /// - Returns: The updated meeting.

    func updateMeeting(id: QualifiedID, parameters: UpdateMeetingParameters) async throws -> MeetingResponse

    /// Delete a meeting.
    ///
    /// - Parameter id: The id of the meeting to delete.

    func deleteMeeting(id: QualifiedID) async throws

}
