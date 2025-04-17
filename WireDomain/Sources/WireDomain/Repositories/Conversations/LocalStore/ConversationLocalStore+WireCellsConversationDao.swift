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

import WireCellsAPI
import WireDataModel

extension ConversationLocalStore: WireCellsConversationDao {

    public func getCellName(
        conversationID: WireCellsAPI
            .WireCellsConversationID
    ) async throws(WireCellsConversationDaoError) -> String {
        do {
            return try await context.perform { [context] in
                guard let conversation = ZMConversation.fetch(
                    with: conversationID.uuid,
                    domain: conversationID.domain,
                    in: context
                ) else {
                    throw WireCellsConversationDaoError.conversationNotFound
                }
                guard let cellName = conversation.cellName else {
                    throw WireCellsConversationDaoError.cellNameNotFound
                }
                return cellName
            }
        } catch let error as WireCellsConversationDaoError {
            throw error
        } catch {
            throw .genericError(error)
        }
    }

    public func setWireCell(
        conversationID: WireCellsAPI.WireCellsConversationID,
        cellName: String
    ) async throws(WireCellsConversationDaoError) {
        do {
            try await context.perform { [context] in
                guard let conversation = ZMConversation.fetch(
                    with: conversationID.uuid,
                    domain: conversationID.domain,
                    in: context
                ) else {
                    throw WireCellsConversationDaoError.conversationNotFound
                }
                conversation.cellName = cellName
                try context.save()
            }
        } catch let error as WireCellsConversationDaoError {
            throw error
        } catch {
            throw .genericError(error)
        }
    }

    public func getAllConversations() async throws(WireCellsConversationDaoError) -> [WireCellsConversation] {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest: NSFetchRequest<ZMConversation> = ZMConversation
                    .fetchRequest() as? NSFetchRequest<ZMConversation> else {
                    throw WireCellsConversationDaoError.storageFailure
                }
                fetchRequest.predicate = NSPredicate(format: "cellName != nil")
                fetchRequest.fetchBatchSize = 100

                let conversations = try context.fetch(fetchRequest)

                return conversations.compactMap { (conversation: ZMConversation) -> WireCellsConversation? in
                    guard let domain = conversation.domain else {
                        return nil
                    }
                    return WireCellsConversation(
                        id: WireCellsAPI.WireCellsConversationID(
                            domain: domain,
                            uuid: conversation.remoteIdentifier
                        ),
                        cellName: conversation.cellName
                    )
                }
            }
        } catch let error as WireCellsConversationDaoError {
            throw error
        } catch {
            throw .genericError(error)
        }
    }
}
