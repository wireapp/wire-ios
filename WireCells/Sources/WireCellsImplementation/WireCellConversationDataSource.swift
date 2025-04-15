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
    // This queue is used to synchronize access to the database.
    // And ensure all database operations are performed on the same queue.
    private let dispatchQueue: DispatchQueue

    init(
        conversationDao: any WireCellsConversationDao,
        dispatchQueue: DispatchQueue
    ) {
        self.conversationDao = conversationDao
    }

    func getCellName(conversationID: WireCellsConversationID) async throws(WireCellsCellConversationRepositoryError) -> String {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [conversationDao] in
                    do {
                        let cellName = try conversationDao.getCellName(conversationID: conversationID)
                        continuation.resume(returning: cellName)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }

    func setWireCell(conversationID: WireCellsConversationID, cellName: String) async throws(WireCellsCellConversationRepositoryError) {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [conversationDao] in
                    do {
                        try conversationDao.setWireCell(
                            conversationID: conversationID,
                            cellName: cellName
                        )
                        continuation.resume(returning: ())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }

    func getConversationNames() async throws(WireCellsCellConversationRepositoryError) -> [(String, String)] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [conversationDao] in
                    do {
                        guard let conversations = try await conversationDao.getAllConversations().first else {
                            continuation.resume(returning: [])
                            return
                        }

                        let names = conversations.compactMap { conv in
                            if let name = conv.name {
                                return (conv.id.description, name)
                            }
                            return nil
                        }
                        continuation.resume(returning: names)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            throw WireCellsCellConversationRepositoryError.genericError(error)
        }
    }
}
