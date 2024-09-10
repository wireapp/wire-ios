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

enum UserEventType: String {

    case clientAdd = "user.client-add"
    case clientRemove = "user.client-remove"
    case connection = "user.connection"
    case contactJoin = "user.contact-join"
    case delete = "user.delete"
    case legalholdDisable = "user.legalhold-disable"
    case legalholdEnable = "user.legalhold-enable"
    case legalholdRequest = "user.legalhold-request"
    case propertiesSet = "user.properties-set"
    case propertiesDelete = "user.properties-delete"
    case pushRemove = "user.push-remove"
    case update = "user.update"
}
