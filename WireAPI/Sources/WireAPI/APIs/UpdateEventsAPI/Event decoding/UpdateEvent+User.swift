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
        switch eventType {
        case .clientAdd:
            self = .user(.clientAdd)

        case .clientRemove:
            self = .user(.clientRemove)

        case .connection:
            self = .user(.connection)

        case .contactJoin:
            self = .user(.contactJoin)

        case .delete:
            self = .user(.delete)

        case .legalholdDisable:
            self = .user(.legalholdDisable)

        case .legalholdEnable:
            self = .user(.legalholdEnable)

        case .legalholdRequest:
            self = .user(.legalholdRequest)

        case .propertiesSet:
            self = .user(.propertiesSet)

        case .propertiesDelete:
            self = .user(.propertiesDelete)

        case .pushRemove:
            self = .user(.pushRemove)

        case .update:
            self = .user(.update)
        }
    }

}
