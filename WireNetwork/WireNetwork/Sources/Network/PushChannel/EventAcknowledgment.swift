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

/// Payload sent via PushChannelV2 for acknowledgment of event in consumable notifications sync system
struct EventAcknowledgment: Encodable {

    struct AcknowledgmentData: Encodable {
        enum CodingKeys: String, CodingKey {
            case deliveryTag = "delivery_tag"
            case multiple
        }

        var deliveryTag: UInt64
        var multiple: Bool
    }

    let type: AcknowledgmentType = .event
    var data: AcknowledgmentData

    init(deliveryTag: UInt64, multiple: Bool) {
        self.data = .init(deliveryTag: deliveryTag, multiple: multiple)
    }
}
