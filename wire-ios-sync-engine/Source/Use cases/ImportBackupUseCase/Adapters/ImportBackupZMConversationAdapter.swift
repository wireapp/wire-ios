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
import WireFoundation

struct ImportBackupZMConversationAdapter: ImportBackupConversationEntityProtocol { // TODO: try to replace by repository (WireDomain)

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        ZMConversation.fetchRequest()
    }

    static func create(
        id: QualifiedID,
        context: NSManagedObjectContext
    ) -> ImportBackupZMConversationAdapter {
        let conversation = ZMConversation.fetchOrCreate(
            with: id.uuid,
            domain: id.domain,
            in: context
        )
        conversation.needsToBeUpdatedFromBackend = true
        conversation.isPendingMetadataRefresh = true
        return ImportBackupZMConversationAdapter(conversation: conversation)
    }

    // MARK: -

    var conversation: ZMConversation

    var id: QualifiedID {
        conversation.qualifiedID ?? .init(uuid: conversation.remoteIdentifier, domain: conversation.domain ?? "")
    }

    var name: String {
        get { conversation.userDefinedName ?? "" }
        nonmutating set { conversation.userDefinedName = newValue }
    }

    init?(_ record: any NSFetchRequestResult) {
        guard let conversation = record as? ZMConversation else { return nil }
        self.init(conversation: conversation)
    }

    private init(conversation: ZMConversation) {
        self.conversation = conversation
    }

}
