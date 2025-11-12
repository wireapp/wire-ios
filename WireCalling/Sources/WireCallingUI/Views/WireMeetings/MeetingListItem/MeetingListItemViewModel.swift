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

import Foundation
import WireCallingDomain

final class MeetingListItemViewModel: ObservableObject {

    package let meeting: Meeting
    package let currentDate: Date
    package let participatingMeetingId: UUID?

    init(
        meeting: Meeting,
        currentDate: Date,
        participatingMeetingId: UUID? = nil
    ) {
        self.meeting = meeting
        self.currentDate = currentDate
        self.participatingMeetingId = participatingMeetingId
    }

    /// The current state of the meeting
    var state: MeetingState {
        meeting.state(at: currentDate, participatingMeetingId: participatingMeetingId)
    }

    /// Human-readable description of the current state for debugging/display
    var stateDescription: String {
        switch state {
        case .scheduled:
            return "Scheduled"
        case .startingSoon:
            return "Starting Soon"
        case .live:
            return "Live"
        case .joined:
            return "Joined"
        case .ended:
            return "Ended"
        }
    }

    // MARK: - State-based UI Properties

    /// Returns true if the meeting is in a state where join/start actions are relevant
    var isActionable: Bool {
        switch state {
        case .startingSoon, .live:
            return true
        case .scheduled, .joined, .ended:
            return false
        }
    }

    /// Returns true if the user is currently in this meeting
    var isActive: Bool {
        state == .joined
    }

    /// Returns true if the meeting has already ended
    var isPast: Bool {
        state == .ended
    }
}
