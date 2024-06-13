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

extension UpdateEvent {

    init(
        eventType: UserEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: UserEventCodingKeys.self)

        switch eventType {
        case .clientAdd:
            let event = try UserClientAddEventDecoder().decode(from: container)
            self = .user(.clientAdd(event))

        case .clientRemove:
            let event = try UserClientRemoveEventDecoder().decode(from: container)
            self = .user(.clientRemove(event))

        case .connection:
            let event = try UserConnectionEventDecoder().decode(from: container)
            self = .user(.connection(event))

        case .contactJoin:
            let event = try UserContactJoinEventDecoder().decode(from: container)
            self = .user(.contactJoin(event))

        case .delete:
            let event = try UserDeleteEventDecoder().decode(from: container)
            self = .user(.delete(event))

        case .legalholdDisable:
            let event = try UserLegalholdDisableEventDecoder().decode(from: container)
            self = .user(.legalholdDisable(event))

        case .legalholdEnable:
            let event = try UserLegalholdEnableEventDecoder().decode(from: container)
            self = .user(.legalholdEnable(event))

        case .legalholdRequest:
            let event = try UserLegalholdRequestEventDecoder().decode(from: container)
            self = .user(.legalholdRequest(event))

        case .propertiesSet:
            let event = try UserPropertiesSetEventDecoder().decode(from: container)
            self = .user(.propertiesSet(event))

        case .propertiesDelete:
            let event = try UserPropertiesDeleteEventDecoder().decode(from: container)
            self = .user(.propertiesDelete(event))

        case .pushRemove:
            self = .user(.pushRemove)

        case .update:
            let event = try UserUpdateEventDecoder().decode(from: container)
            self = .user(.update(event))
        }
    }

}
