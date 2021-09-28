// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

extension ZMUser {

    var qualifiedID: Payload.QualifiedID? {
        guard
            let context = managedObjectContext,
            let uuid = remoteIdentifier,
            let domain = domain ?? ZMUser.selfUser(in: context).domain
        else {
            return nil
        }

        return Payload.QualifiedID(uuid: uuid, domain: domain)
    }

}

extension ZMConversation {

    var qualifiedID: Payload.QualifiedID? {
        guard
            let context = managedObjectContext,
            let uuid = remoteIdentifier,
            let domain = domain ?? ZMUser.selfUser(in: context).domain
        else {
            return nil
        }

        return Payload.QualifiedID(uuid: uuid, domain: domain)
    }

}

extension Collection where Element == ZMUser {

    var qualifiedUserIDs: [Payload.QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}

extension Collection where Element == ZMConversation {

    var qualifiedIDs: [Payload.QualifiedID]? {
        let list = compactMap(\.qualifiedID)

        return list.count == count ? list : nil
    }

}
