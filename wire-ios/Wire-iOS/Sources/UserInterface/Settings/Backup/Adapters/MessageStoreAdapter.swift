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
import WireBackup
import WireDomain
import WireFoundation
import WireDataModel

struct MessageStoreAdapter: MessageStoreProtocol {

    let messageLocalStore: any MessageLocalStoreProtocol

    init(messageLocalStore: any MessageLocalStoreProtocol) {
        self.messageLocalStore = messageLocalStore
    }

    func totalMessageCount() async throws -> Int {
        try await messageLocalStore.totalBackupableMessageCount()
    }

    func fetchAllMessages() async throws -> [MessageEntity] {
        try await messageLocalStore.fetchAllBackupableMessages().map(MessageEntity.init)
    }

    // MARK: -

    struct MessageEntity: MessageEntityProtocol {
        typealias QualifiedID = WireFoundation.QualifiedID

        var id: String {
            fatalError()
        }

        var name: String {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        var conversationID: QualifiedID {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        var senderUserID: QualifiedID {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        var senderClientID: String? {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        var creationDate: Date {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        var content: WireBackup.MessageContent {
            get { fatalError() }
            nonmutating set { fatalError() }
        }

        init(_ message: ZMClientMessage) {
            fatalError("TODO")
        }

    }

}
