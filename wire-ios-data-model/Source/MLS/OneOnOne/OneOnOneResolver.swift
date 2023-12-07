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

public protocol OneOnOneResolverInterface {

    func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext,
        completion: @escaping (Swift.Result<Void, Error>) -> Void
    )

}

public final class OneOnOneResolver: OneOnOneResolverInterface {

    // MARK: - Dependencies

    private let protocolSelector: OneOnOneProtocolSelectorInterface
    private let migrator: OneOnOneMigratorInterface

    // MARK: - Life cycle

    public init(
        protocolSelector: OneOnOneProtocolSelectorInterface,
        migrator: OneOnOneMigratorInterface
    ) {
        self.protocolSelector = protocolSelector
        self.migrator = migrator
    }

    // MARK: - Methods

    public func resolveOneOnOneConversation(
        with userID: QualifiedID,
        in context: NSManagedObjectContext,
        completion: @escaping (Swift.Result<Void, Error>) -> Void
    ) {
        switch protocolSelector.getProtocolForUser(
            with: userID,
            in: context
        ) {
        case nil:
            guard
                let otherUser = ZMUser.fetch(with: userID, in: context),
                let conversation = otherUser.connection?.conversation
            else {
                completion(.success(()))
                return
            }

            conversation.isForcedReadOnly = true
            completion(.success(()))

        case .proteus?:
            completion(.success(()))

        case .mls?:
            Task {
                do {
                    try await migrator.migrateToMLS(
                        userID: userID,
                        in: context
                    )
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

}
