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

struct CreateBackupZMConversationAdapter: CreateBackupConversationEntityProtocol {

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        ZMConversation.fetchRequest() // TODO: self conversations shouldn't be fetched
    }

    let id: QualifiedID
    let name: String

    init?(_ record: any NSFetchRequestResult) {
        guard let conversation = record as? ZMConversation, let qualifiedID = conversation.qualifiedID else { return nil } // TODO: prevent silent failure?

        id = qualifiedID
        name = conversation.name ?? ""
    }

}
