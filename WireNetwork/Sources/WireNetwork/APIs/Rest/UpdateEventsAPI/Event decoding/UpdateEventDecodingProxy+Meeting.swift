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

extension UpdateEventDecodingProxy {

    init(
        eventType: MeetingEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: MeetingEventCodingKeys.self)

        switch eventType {
        case .create:
            let event = try MeetingCreateEventDecoder().decode(from: container)
            updateEvent = .meeting(.create(event))

        case .delete:
            let event = try MeetingDeleteEventDecoder().decode(from: container)
            updateEvent = .meeting(.delete(event))

        case .update:
            let event = try MeetingUpdateEventDecoder().decode(from: container)
            updateEvent = .meeting(.update(event))
        }
    }

}
