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

import Foundation
import WireDataModel
import WireDomainPkg

struct CreateBackupZMMessageAdapter: CreateBackupMessageEntityProtocol {

    typealias QualifiedID = WireDomainPkg.QualifiedID

    static func fetchRequest() -> NSFetchRequest<any NSFetchRequestResult> {
        ZMMessage.fetchRequest()
    }

    let id: String
    let conversationID: QualifiedID
    let senderUserID: QualifiedID
    let senderClientID: String
    let creationDate: Date
    let content: CreateBackupMessageContent

    init?(_ record: any NSFetchRequestResult) {
        guard let message = record as? ZMMessage else { return nil }
        fatalError()

//        self.qualifiedID = qualifiedID
//        name = user.name ?? ""
//        handle = user.handle ?? ""
    }

}
