//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct UpdateEventListResponseV0: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case notifications
        case time
        case hasMore = "has_more"
    }

    let notifications: [UpdateEventEnvelopeV0]
    let time: UTCTime?
    let hasMore: Bool?

    func toAPIModel() -> PayloadPager<UpdateEventEnvelope>.Page {
        let eventEnvelopes = notifications.map {
            $0.toAPIModel()
        }

        let lastNonTransientEvent = eventEnvelopes.last {
            !$0.isTransient
        }

        return .init(
            element: notifications.map { $0.toAPIModel() },
            hasMore: hasMore ?? false,
            nextStart: lastNonTransientEvent?.id.transportString() ?? ""
        )
    }
}
