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
    case missingQualifiedID
    case failedToCreateConversation(ConversationCreationFailure)
    case cannotFetchMLSConversation
    case mlsConversationNotFound
    case failedToSyncMLSConversation(SyncMLSOneToOneConversationActionError)

}

public struct CreateTeamOneOnOneConversationUseCase: CreateTeamOneOnOneConversationUseCaseInterface {

    typealias Completion = (Swift.Result<ZMConversation, CreateTeamOneOnOneConversationError>) -> Void

    private let viewContext: NSManagedObjectContext
    private let oneOnOneResolver: OneOnOneResolverInterface

    init(
        viewContext: NSManagedObjectContext,
        oneOnOneResolver: OneOnOneResolverInterface
    ) {
        self.viewContext = viewContext
        self.oneOnOneResolver = oneOnOneResolver
    }

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

        guard
            let userID = user.remoteIdentifier,
            let userDomain = user.domain ?? BackendInfo.domain
        else {
            completion(.failure(.missingQualifiedID))
            return
        }

        let qualifiedID = QualifiedID(
            uuid: userID,
            domain: userDomain
        )

        // 1. We should probably check if we need to do this on the
        // sync context rather than the view context.

        // 2. We can use this resolver now, but we may need to make some
        // slight changes. For instance, we probably need to fetch the
        // other users supported protocols before resolving, we could
        // do it inside the resolver as the first step.

        // 3. The specs say we should fetch the mls one on one and create
        // it locally, but delay establishing the group via core crypto and
        // adding the other user until we send the first message (so the other
        // user only sees the 1-1 with a new message). Android didn't do this yet
        // and it's a nice to have. For now we can ignore that and just create
        // and establish the group in one step here via the resolver.

        oneOnOneResolver.resolveOneOnOneConversation(
            with: qualifiedID,
            in: viewContext
        ) {
            switch $0 {
            case .success:
                // 4. The completion expects a ZMConversation, so we may
                // need to return a conversation id or object id in the
                // success case and fetch it from the view context.
                break

            case .failure(let error):
                // 5. The completion expects an `CreateTeamOneOnOneConversationError`
                // so we need to map or wrap `error`.
                break
            }
        }

        // 6. This is what I did before creating the resolver. I
        // leave it here just for reference but we should try
        // to replace it with the resolver.

//        resolveMessageProtocol(with: qualifiedID) {
//            switch $0 {
//            case nil:
//                createReadOnlyProteusConversation(
//                    with: user,
//                    completion: completion
//                )
//
//            case .proteus?:
//                createProteusConversation(
//                    with: user,
//                    completion: completion
//                )
//
//            case .mls?:
//                createMLSConversation(
//                    with: user,
//                    completion: completion
//                )
//            }
//        }
    }

    // MARK: - Helpers

    private func resolveMessageProtocol(
        with userID: QualifiedID,
        completion: @escaping (MessageProtocol?) -> Void
    ) {
        let selfUser = ZMUser.selfUser(in: viewContext)
        let selfSupportedProtocols = selfUser.supportedProtocols

        var action = FetchSupportedProtocolsAction(userID: userID)
        action.perform(in: viewContext.notificationContext) {
            switch $0 {
            case .success(let supportedProtocols):
                let commonProtocols = selfSupportedProtocols.intersection(supportedProtocols)
                
                if commonProtocols.contains(.mls) {
                    completion(.mls)
                } else if commonProtocols.contains(.proteus) {
                    completion(.proteus)
                } else {
                    completion(nil)
                }

            case .failure:
                completion(nil)
            }
        }
    }

    private func createReadOnlyProteusConversation(
        with user: ZMUser,
        completion: @escaping Completion
    ) {
        createProteusConversation(with: user) {
            switch $0 {
            case .success(let conversation):
                conversation.isForcedReadOnly = true
                completion(.success(conversation))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func createProteusConversation(
        with user: ZMUser,
        completion: @escaping Completion
    ) {
        let service = ConversationService(context: viewContext)
        service.createTeamOneToOneConversation(user: user) { result in
            completion(result.mapError {
                .failedToCreateConversation($0)
            })
        }
    }

    private func createMLSConversation(
        with user: ZMUser,
        completion: @escaping Completion
    ) {
        guard
            let userID = user.remoteIdentifier,
            let domain = user.domain ?? BackendInfo.domain
        else {
            completion(.failure(.cannotFetchMLSConversation))
            return
        }

        var action = SyncMLSOneToOneConversationAction(
            userID: userID,
            domain: domain
        )

        action.perform(in: viewContext.notificationContext) {
            switch $0 {
            case .success(let mlsGroupID):
                if let conversation = ZMConversation.fetch(
                    with: mlsGroupID,
                    in: viewContext
                ) {
                    completion(.success(conversation))
                } else {
                    completion(.failure(.mlsConversationNotFound))
                }

            case .failure(let error):
                completion(.failure(.failedToSyncMLSConversation(error)))
            }
        }
    }

}

public extension ZMUserSession {

    func createTeamOneOnOneConversationUseCase() -> CreateTeamOneOnOneConversationUseCaseInterface {
        return CreateTeamOneOnOneConversationUseCase(viewContext: viewContext)
    }

}
