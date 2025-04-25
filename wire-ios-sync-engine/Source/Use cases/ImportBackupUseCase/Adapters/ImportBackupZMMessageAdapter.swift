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

struct ImportBackupZMMessageAdapter: ImportBackupMessageEntityProtocol {

    // typealias QualifiedID = WireDomainPackage.QualifiedID

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        fatalError("TODO")
//        let fetchRequest = ZMConversation.fetchRequest()
//        fetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"] // qualified id properties
//        return fetchRequest
    }

    var conversation: ZMConversation

    /*
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
     */

    var name: String {
        get { conversation.userDefinedName ?? "" }
        nonmutating set { conversation.userDefinedName = newValue }
    }

    /*
    var handle: String {
        get { user.handle ?? "" }
        nonmutating set { user.handle = newValue }
    }
     */

    init(context: NSManagedObjectContext) {
        fatalError()
//        user = ZMUser(context: context)
//        user.needsToBeUpdatedFromBackend = true
    }

    init?(_ record: any NSFetchRequestResult) {
        fatalError()
//        guard let user = record as? ZMUser else { return nil }
//        self.user = user
    }

}
