//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol CreateTeamOneOnOneConversationUseCaseInterface {

    func invoke(
        user: UserType,
        completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void
    )

}

public enum CreateTeamOneOnOneConversationError: Error, Equatable {

    case userIsNotATeamMember
    case failedToMaterializeUser
    case failedToCreateConversation(ConversationCreationFailure)

}

public struct CreateTeamOneOnOneConversationUseCase: CreateTeamOneOnOneConversationUseCaseInterface {

    private let viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    // If default message protocol is mls, and both sides support mls, then fetch mls one to one.
    // When sending a message... check if one to one mls, if it needs establishing
    //
    // else if proteus is supported, then proteus.
    // then create a read only conversation

    public func invoke(
        user: UserType,
        completion: @escaping (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void
    ) {
        guard user.isTeamMember else {
            completion(.failure(.userIsNotATeamMember))
            return
        }

        guard let user = user.materialize(in: viewContext) else {
            completion(.failure(.failedToMaterializeUser))
            return
        }

        let service = ConversationService(context: viewContext)
        service.createTeamOneToOneConversation(user: user) { result in
            completion(result.mapError {
                .failedToCreateConversation($0)
            })
        }
    }

}

public extension ZMUserSession {

    func createTeamOneOnOneConversationUseCase() -> CreateTeamOneOnOneConversationUseCaseInterface {
        return CreateTeamOneOnOneConversationUseCase(viewContext: viewContext)
    }

}
