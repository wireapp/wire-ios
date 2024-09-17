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

    /// Adds a user client.
    ///
    /// - Parameter userClient: The user client to add.
    func addUserClient(_ userClient: WireAPI.UserClient) async throws

}

public final class UserRepository: UserRepositoryProtocol {

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        usersAPI: any UsersAPI
    ) {
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

    public func addUserClient(_ userClient: WireAPI.UserClient) async throws {
        await context.perform { [context] in
            let localUserClient: (client: WireDataModel.UserClient, isNew: Bool) = {
                if let existingClient = UserClient.fetchExistingUserClient(
                    with: userClient.id,
                    in: context
                ) {
                    return (client: existingClient, isNew: false)
                } else {
                    let newClient = UserClient.insertNewObject(in: context)
                    return (client: newClient, isNew: true)
                }
            }()

            let localClient = localUserClient.client
            let isNewClient = localUserClient.isNew

            localClient.label = userClient.label
            localClient.type = userClient.type.toDomainModel()
            localClient.model = userClient.model
            localClient.deviceClass = userClient.deviceClass?.toDomainModel()
            localClient.activationDate = userClient.activationDate
            localClient.lastActiveDate = userClient.lastActiveDate
            localClient.remoteIdentifier = userClient.id

            let selfUser = ZMUser.selfUser(in: context)
            localClient.user = localClient.user ?? selfUser

            if isNewClient {
                localClient.needsSessionMigration = selfUser.domain == nil
            }

            if localClient.isLegalHoldDevice, isNewClient {
                selfUser.legalHoldRequest = nil
                selfUser.needsToAcknowledgeLegalHoldStatus = true
            }

            if !localClient.isSelfClient() {
                localClient.mlsPublicKeys = .init(
                    ed25519: userClient.mlsPublicKeys?.ed25519,
                    ed448: userClient.mlsPublicKeys?.ed448,
                    p256: userClient.mlsPublicKeys?.p256,
                    p384: userClient.mlsPublicKeys?.p384,
                    p521: userClient.mlsPublicKeys?.p512
                )
            }

            if let selfClient = selfUser.selfClient(),
               localClient.remoteIdentifier != selfClient.remoteIdentifier, isNewClient,
               let selfClientActivationDate = selfClient.activationDate,
               localClient.activationDate?.compare(selfClientActivationDate) == .orderedDescending {
                localClient.needsToNotifyUser = true
            }

            selfUser.selfClient()?.addNewClientToIgnored(localClient)
            selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(Set([localClient]))
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
