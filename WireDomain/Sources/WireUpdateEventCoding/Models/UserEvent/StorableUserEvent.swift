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

enum StorableUserEvent: Equatable, Codable, Sendable {

    case clientAdd(StorableUserClientAddEvent)
    case clientRemove(StorableUserClientRemoveEvent)
    case connection(StorableUserConnectionEvent)
    case contactJoin(StorableUserContactJoinEvent)
    case delete(StorableUserDeleteEvent)
    case legalholdDisable(StorableUserLegalholdDisableEvent)
    case legalholdEnable(StorableUserLegalholdEnableEvent)
    case legalholdRequest(StorableUserLegalholdRequestEvent)
    case propertiesSet(StorableUserPropertiesSetEvent)
    case propertiesDelete(StorableUserPropertiesDeleteEvent)
    case pushRemove
    case update(StorableUserUpdateEvent)

    init(_ value: WireNetwork.UserEvent) {
        switch value {
        case let .clientAdd(clientAdd):
            self = .clientAdd(StorableUserClientAddEvent(clientAdd))
        case let .clientRemove(clientRemove):
            self = .clientRemove(StorableUserClientRemoveEvent(clientRemove))
        case let .connection(connection):
            self = .connection(StorableUserConnectionEvent(connection))
        case let .contactJoin(contactJoin):
            self = .contactJoin(StorableUserContactJoinEvent(contactJoin))
        case let .delete(delete):
            self = .delete(StorableUserDeleteEvent(delete))
        case let .legalholdDisable(legalholdDisable):
            self = .legalholdDisable(StorableUserLegalholdDisableEvent(legalholdDisable))
        case let .legalholdEnable(legalholdEnable):
            self = .legalholdEnable(StorableUserLegalholdEnableEvent(legalholdEnable))
        case let .legalholdRequest(legalholdRequest):
            self = .legalholdRequest(StorableUserLegalholdRequestEvent(legalholdRequest))
        case let .propertiesSet(propertiesSet):
            self = .propertiesSet(StorableUserPropertiesSetEvent(propertiesSet))
        case let .propertiesDelete(propertiesDelete):
            self = .propertiesDelete(StorableUserPropertiesDeleteEvent(propertiesDelete))
        case .pushRemove:
            self = .pushRemove
        case let .update(update):
            self = .update(StorableUserUpdateEvent(update))
        }
    }

    func toAPIModel() -> WireNetwork.UserEvent {
        switch self {
        case let .clientAdd(clientAdd):
            .clientAdd(clientAdd.toAPIModel())
        case let .clientRemove(clientRemove):
            .clientRemove(clientRemove.toAPIModel())
        case let .connection(connection):
            .connection(connection.toAPIModel())
        case let .contactJoin(contactJoin):
            .contactJoin(contactJoin.toAPIModel())
        case let .delete(delete):
            .delete(delete.toAPIModel())
        case let .legalholdDisable(legalholdDisable):
            .legalholdDisable(legalholdDisable.toAPIModel())
        case let .legalholdEnable(legalholdEnable):
            .legalholdEnable(legalholdEnable.toAPIModel())
        case let .legalholdRequest(legalholdRequest):
            .legalholdRequest(legalholdRequest.toAPIModel())
        case let .propertiesSet(propertiesSet):
            .propertiesSet(propertiesSet.toAPIModel())
        case let .propertiesDelete(propertiesDelete):
            .propertiesDelete(propertiesDelete.toAPIModel())
        case .pushRemove:
            .pushRemove
        case let .update(update):
            .update(update.toAPIModel())
        }
    }

}
