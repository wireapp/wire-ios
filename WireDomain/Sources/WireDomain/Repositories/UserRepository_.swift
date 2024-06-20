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

protocol UserRepositoryProtocol_ {

    func pullKnownUsers() async throws

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws

}

final class UserRepository_: UserRepositoryProtocol_ {

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI

    init(context: NSManagedObjectContext, usersAPI: any UsersAPI) {
        self.context = context
        self.usersAPI = usersAPI
    }

    func pullKnownUsers() async throws {
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

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        do {
            let userList = try await usersAPI.getUsers(userIDs: userIDs.toAPIModel())

            await context.perform {
                userList.found.forEach {
                    self.persistUser(from: $0)
                }
            }
        } catch {
            throw UserRepositoryError.failedToFetchRemotely(error)
        }
    }

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

extension Collection where Element == WireDataModel.QualifiedID {

    func toAPIModel() -> [WireAPI.QualifiedID] {
        map({ $0.toAPIModel() })
    }

}

extension WireDataModel.QualifiedID {

    func toAPIModel() -> WireAPI.QualifiedID {
        UserID(uuid: uuid, domain: domain)
    }

}

extension WireAPI.QualifiedID {

    func toDomainModel() -> WireDataModel.QualifiedID {
        WireDataModel.QualifiedID(uuid: uuid, domain: domain)
    }

}

extension Set where Element == WireAPI.SupportedProtocol {

    func toDomainModel() -> Set<WireDataModel.MessageProtocol> {
        .init(map({ $0.toDomainModel() }))
    }

}

extension WireAPI.SupportedProtocol {

    func toDomainModel() -> WireDataModel.MessageProtocol {
        switch self {
        case .mls: .mls
        case .proteus: .proteus
        }
    }
}
