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

import WireBackup
import WireDataModel
import WireFoundation

extension BackupLocalStore {

    private var conversationFetchRequest: NSFetchRequest<any NSFetchRequestResult> {
        let fetchRequest = ZMConversation.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }

    func fetchAllConversationIDs() async throws -> Set<WireFoundation.QualifiedID> {
        let fetchRequest = ZMConversation.fetchRequest()
        fetchRequest.propertiesToFetch = ["remoteIdentifier_data", "domain"]
        return try await backupContext.perform { [backupContext] in
            let conversations = try backupContext.fetch(fetchRequest) as! [ZMConversation]
            return Set(conversations.compactMap(\.qualifiedID).map(WireFoundation.QualifiedID.init))
        }
    }

    func fetchAllConversations() -> AsyncThrowingStream<ConversationBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    try await backupContext.perform {
                        let conversations = try backupContext.fetch(conversationFetchRequest) as! [ZMConversation]
                        for conversation in conversations {
                            autoreleasepool {
                                if let backupConversation = ConversationBackupModel(conversation) {
                                    continuation.yield(backupConversation)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

}

// MARK: -

private extension ConversationBackupModel {

    init?(_ conversation: ZMConversation) {
        guard let qualifiedID = conversation.qualifiedID else { return nil }

        self.init(
            qualifiedID: QualifiedID(qualifiedID),
            name: conversation.name ?? ""
        )
    }

}
