//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

extension ZMUserSession {

    /// Create a new team one on one with another user.
    ///
    /// - Parameters:
    ///   - user: the other user.
    ///   - completion: a result handler.

    public func createTeamOneOnOne(
        with user: UserType,
        completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void
    ) {
        guard let viewUser = user.materialize(in: viewContext) else {
            completion(.failure(.userDoesNotExist))
            return
        }

        Task {
            do {
                let syncContext = self.syncContext

                let (useCase, syncUser) = try await syncContext.perform {
                    guard let syncUser = try? syncContext.existingObject(with: viewUser.objectID) as? ZMUser else {
                        throw CreateTeamOneOnOneConversationError.userDoesNotExist
                    }

                    let migrator = syncContext.mlsService.map(OneOnOneMigrator.init(mlsService:))
                    let service = ConversationService(context: syncContext)
                    let useCase = CreateTeamOneOnOneConversationUseCase(migrator: migrator, service: service)

                    return (useCase, syncUser)
                }

                let objectID = try await useCase.invoke(
                    with: syncUser,
                    syncContext: syncContext
                )

                try await self.viewContext.perform {
                    guard let conversation = try? self.viewContext.existingObject(with: objectID) as? ZMConversation else {
                        throw CreateTeamOneOnOneConversationError.conversationNotFound
                    }

                    completion(.success(conversation))
                }

            } catch let error as CreateTeamOneOnOneConversationError {
                await self.viewContext.perform {
                    completion(.failure(error))
                }
            }
        }
    }
}
