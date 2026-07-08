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

import WireNetwork

struct MeetingCreateEventProcessor: MeetingCreateEventProcessorProtocol {

    let meetingsAPI: any MeetingsAPI
    let localStore: any MeetingLocalStoreProtocol

    func processEvent(_ event: MeetingCreateEvent) async throws {
        // The event only carries the meeting id and there is no endpoint
        // to fetch a single meeting, so refetch the list to get the details.
        let meetings = try await meetingsAPI.listMeetings()

        if let meeting = meetings.first(where: { $0.id == event.meetingID }) {
            await localStore.storeMeeting(meeting)
        } else {
            // The meeting no longer exists on the backend.
            await localStore.deleteMeeting(
                id: event.meetingID.id,
                domain: event.meetingID.domain
            )
        }
    }

}
