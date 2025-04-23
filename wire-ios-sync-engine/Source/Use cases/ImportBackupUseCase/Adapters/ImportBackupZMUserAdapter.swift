//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModel
import WireDomainPackage

struct ImportBackupZMUserAdapter: ImportBackupUserEntityProtocol {

    typealias QualifiedID = WireDomainPackage.QualifiedID

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        let fetchRequest = ZMUser.fetchRequest() // TODO: what about the self user?
        fetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"] // qualified id properties
        return fetchRequest
    }

    static func fetchOrCreate(
        id: QualifiedID,
        context: NSManagedObjectContext
    ) -> ImportBackupZMUserAdapter {
        let user = ZMUser.fetchOrCreate(
            with: id.uuid,
            domain: id.domain,
            in: context
        )
        user.needsToBeUpdatedFromBackend = true
        return ImportBackupZMUserAdapter(user: user)
    }

    // MARK: -

    var user: ZMUser

    var id: QualifiedID {
        get {
            let qualifiedID = user.qualifiedID ?? .init(uuid: user.remoteIdentifier, domain: user.domain ?? "")
            return QualifiedID(qualifiedID)
        }
        nonmutating set {
            user.remoteIdentifier = newValue.uuid
            user.domain = newValue.domain
        }
    }

    var name: String {
        get { user.name ?? "" }
        nonmutating set { user.name = newValue }
    }

    var handle: String {
        get { user.handle ?? "" }
        nonmutating set { user.handle = newValue }
    }

    init?(_ record: any NSFetchRequestResult) {
        guard let user = record as? ZMUser else { return nil }
        self.init(user: user)
    }

    private init(user: ZMUser) {
        self.user = user
    }

}
