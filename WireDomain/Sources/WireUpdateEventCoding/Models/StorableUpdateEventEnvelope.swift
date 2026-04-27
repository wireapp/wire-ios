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
import WireNetwork

struct StorableUpdateEventEnvelope: Equatable, Codable, Sendable {

    private let id: UUID
    private let events: [StorableUpdateEvent]
    private let isTransient: Bool

    init(_ value: WireNetwork.UpdateEventEnvelope) {
        self.id = value.id
        self.events = value.events.map(StorableUpdateEvent.init)
        self.isTransient = value.isTransient
    }

    func toAPIModel() -> WireNetwork.UpdateEventEnvelope {
        .init(
            id: id,
            events: events.map { $0.toAPIModel() },
            isTransient: isTransient
        )
    }

}
