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

enum PrimaryKeyGenerator {
    static func generateKey(for object: NSManagedObject, entityName: String) -> String {
        let remoteIdentifierData = object.value(forKey: ZMManagedObject.remoteIdentifierDataKey()) as? Data

        switch entityName {
        case ZMUser.entityName():
            let remoteIdentifier = remoteIdentifierData.flatMap(UUID.init(data:))
            let domain = object.value(forKeyPath: #keyPath(ZMUser.domain)) as? String

            return ZMUser.primaryKey(from: remoteIdentifier, domain: domain)

        case ZMConversation.entityName():
            let remoteIdentifier = remoteIdentifierData.flatMap(UUID.init(data:))
            let domain = object.value(forKeyPath: #keyPath(ZMConversation.domain)) as? String

            return ZMConversation.primaryKey(from: remoteIdentifier, domain: domain)

        case Team.entityName():

            return remoteIdentifierData.flatMap { UUID(data: $0)?.uuidString } ?? "<nil>"

        default:
            fatal("Entity named \(entityName) is not supported")
        }
    }
}
