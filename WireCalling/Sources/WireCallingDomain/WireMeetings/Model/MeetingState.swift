//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Represents the different states a meeting can be in relative to the current time
/// and user's participation status.
public enum MeetingState: Equatable, Sendable {

    /// Meeting is scheduled and will start in more than 5 minutes
    case scheduled

    /// Meeting will start within 5 minutes
    case startingSoon

    /// Meeting is live/happening now, but the user has not joined yet
    case live

    /// User has joined and is actively in the meeting
    case joined

    /// Meeting has ended
    case ended

    /// Determines the state of a meeting based on current time and participation status
    /// - Parameters:
    ///   - meeting: The meeting to evaluate
    ///   - currentDate: The current date/time
    ///   - participatingMeetingId: Optional ID of the meeting the user is currently participating in
    /// - Returns: The appropriate meeting state
    public static func determine(
        for meeting: Meeting,
        at currentDate: Date,
        participatingMeetingId: UUID? = nil
    ) -> MeetingState {
        // Check if user is participating in this meeting
        if let participatingId = participatingMeetingId, participatingId == meeting.id {
            return .joined
        }

        // Check if meeting has ended
        if currentDate >= meeting.end {
            return .ended
        }

        // Check if meeting is currently happening
        if currentDate >= meeting.start && currentDate < meeting.end {
            return .live
        }

        // Calculate time until meeting starts
        let timeUntilStart = meeting.start.timeIntervalSince(currentDate)
        let fiveMinutesInSeconds: TimeInterval = 5 * 60

        // Check if meeting starts within 5 minutes
        if timeUntilStart > 0 && timeUntilStart <= fiveMinutesInSeconds {
            return .startingSoon
        }

        // Meeting is more than 5 minutes away
        return .scheduled
    }
}

extension Meeting {

    /// Convenience method to get the state of this meeting
    /// - Parameters:
    ///   - currentDate: The current date/time
    ///   - participatingMeetingId: Optional ID of the meeting the user is currently participating in
    /// - Returns: The appropriate meeting state
    public func state(
        at currentDate: Date,
        participatingMeetingId: UUID? = nil
    ) -> MeetingState {
        MeetingState.determine(
            for: self,
            at: currentDate,
            participatingMeetingId: participatingMeetingId
        )
    }
}
