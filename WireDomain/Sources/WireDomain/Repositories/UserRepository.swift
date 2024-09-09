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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Facilitate access to users related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserRepositoryProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() -> ZMUser

    /// Fetch and persist all locally known users

    func pullKnownUsers() async throws

    /// Fetch and persist a list of users
    ///
    /// - parameters:
    ///     - userIDs: IDs of users to fetch

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws

}

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI

    // MARK: - Object lifecycle

    public init(context: NSManagedObjectContext, usersAPI: any UsersAPI) {
        self.context = context
        self.usersAPI = usersAPI
    }

    // MARK: - Public

    public func fetchSelfUser() -> ZMUser {
        ZMUser.selfUser(in: context)
    }

    public func pullKnownUsers() async throws {
        let knownUserIDs: [WireDataModel.QualifiedID]

        do {
            knownUserIDs = try await context.perform {
                let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
                let knownUsers = try self.context.fetch(fetchRequest)
                return knownUsers.compactMap(\.qualifiedID)
            }
        } catch {
            throw UserRepositoryError.failedToCollectKnownUsers(error)
        }

        try await pullUsers(userIDs: knownUserIDs)
    }

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDs.toAPIModel())

            await context.perform {
                for user in userList.found {
                    self.persistUser(from: user)
                }
            }
        } catch {
            throw UserRepositoryError.failedToFetchRemotely(error)
        }
    }

    // MARK: - Private

    private func persistUser(from user: WireAPI.User) {
        let persistedUser = ZMUser.fetchOrCreate(with: user.id.uuid, domain: user.id.domain, in: context)

        guard user.deleted == false else {
            return persistedUser.markAccountAsDeleted(at: Date())
        }

        persistedUser.name = user.name
        persistedUser.handle = user.handle
        persistedUser.teamIdentifier = user.teamID
        persistedUser.accentColorValue = Int16(user.accentID)
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .preview })?.key
        persistedUser.previewProfileAssetIdentifier = user.assets.first(where: { $0.size == .complete })?.key
        persistedUser.emailAddress = user.email
        persistedUser.expiresAt = user.expiresAt
        persistedUser.serviceIdentifier = user.service?.id.transportString()
        persistedUser.providerIdentifier = user.service?.provider.transportString()
        persistedUser.supportedProtocols = user.supportedProtocols?.toDomainModel() ?? [.proteus]
        persistedUser.needsToBeUpdatedFromBackend = false
    }
}
