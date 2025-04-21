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
import WireCellsAPI

final class WireCellConversationDataSource: WireCellsCellConversationRepository {
    private let conversationDao: any WireCellsConversationDao

    init(conversationDao: any WireCellsConversationDao) {
        self.conversationDao = conversationDao
    }

    func getCellName(conversationID: WireCellsConversationID) async throws(WireCellsCellConversationRepositoryError)
        -> String {
        do {
            return try await conversationDao.getCellName(conversationID: conversationID)
        } catch WireCellsConversationDaoError.cellNameNotFound {
            throw WireCellsCellConversationRepositoryError.cellNameNotFound
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }

    func setWireCell(
        conversationID: WireCellsConversationID,
        cellName: String
    ) async throws(WireCellsCellConversationRepositoryError) {
        do {
            try await conversationDao.setWireCell(
                conversationID: conversationID,
                cellName: cellName
            )
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }

    func getConversationNames() async throws(WireCellsCellConversationRepositoryError) -> [WireCellsConversation] {
        do {
            return try await conversationDao.getAllConversations()
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }
}
