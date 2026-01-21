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

import Foundation
import WireFoundation
import WireMessagingDomain

final class WireDriveConversationDataSource: WireDriveNodeConversationRepository {
    private let conversationDAO: any WireDriveConversationDAO

    init(conversationDAO: any WireDriveConversationDAO) {
        self.conversationDAO = conversationDAO
    }

    func getCellName(conversationID: QualifiedID) async throws(WireDriveNodeConversationRepositoryError)
        -> String {
        do {
            return try await conversationDAO.getCellName(conversationID: conversationID)
        } catch WireDriveConversationDAOError.cellNameNotFound {
            throw WireDriveNodeConversationRepositoryError.cellNameNotFound
        } catch {
            throw WireDriveNodeConversationRepositoryError.genericError(error)
        }
    }

    func setWireCell(
        conversationID: QualifiedID,
        cellName: String
    ) async throws(WireDriveNodeConversationRepositoryError) {
        do {
            try await conversationDAO.setWireCell(
                conversationID: conversationID,
                cellName: cellName
            )
        } catch {
            throw WireDriveNodeConversationRepositoryError.genericError(error)
        }
    }

    func getConversationNames() async throws(WireDriveNodeConversationRepositoryError) -> [WireDriveConversation] {
        do {
            return try await conversationDAO.getAllConversations()
        } catch {
            throw WireDriveNodeConversationRepositoryError.genericError(error)
        }
    }
}
