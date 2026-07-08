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

enum StorableMeetingEvent: Equatable, Codable, Sendable {

    case create(StorableMeetingCreateEvent)
    case delete(StorableMeetingDeleteEvent)
    case update(StorableMeetingUpdateEvent)

    init(_ value: WireNetwork.MeetingEvent) {
        switch value {
        case let .create(event):
            self = .create(StorableMeetingCreateEvent(event))
        case let .delete(event):
            self = .delete(StorableMeetingDeleteEvent(event))
        case let .update(event):
            self = .update(StorableMeetingUpdateEvent(event))
        }
    }

    func toAPIModel() -> WireNetwork.MeetingEvent {
        switch self {
        case let .create(event):
            .create(event.toAPIModel())
        case let .delete(event):
            .delete(event.toAPIModel())
        case let .update(event):
            .update(event.toAPIModel())
        }
    }

}
