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
import WireFoundation

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
    
    /// Updates a user.
    
    func updateUser(_ event: UserUpdateEvent) async throws

}

public final class UserRepository: UserRepositoryProtocol {

    private let context: NSManagedObjectContext
    private let usersAPI: any UsersAPI

    public init(context: NSManagedObjectContext, usersAPI: any UsersAPI) {
        self.context = context
        self.usersAPI = usersAPI
    }

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
    
    public func updateUser(_ event: UserUpdateEvent) async throws {
        await context.perform { [self] in

            let user = ZMUser.fetchOrCreate(
                with: event.id,
                domain: event.qualifiedID.domain,
                in: context
            )
            
            if let qualifiedID = event.qualifiedID, BackendInfo.isFederationEnabled {
                precondition(user.remoteIdentifier == nil || user.remoteIdentifier == qualifiedID.uuid)
                precondition(user.domain == nil || user.domain == qualifiedID.domain)

                user.remoteIdentifier = qualifiedID.uuid
                user.domain = qualifiedID.domain
            } else if let id = event.id {
                precondition(user.remoteIdentifier == nil || user.remoteIdentifier == id)
                user.remoteIdentifier = id
            }

//            if let serviceID = event.serviceID {
//                user.serviceIdentifier = serviceID.id.transportString()
//                user.providerIdentifier = serviceID.provider.transportString()
//            }

//            if payload.updatedKeys.contains(.teamID) {
//                user.teamIdentifier = payload.teamID
//                user.createOrDeleteMembershipIfBelongingToTeam()
//            }

//            if payload.SSOID != nil {
//                if let subject = payload.SSOID?.subject {
//                    user.usesCompanyLogin = !subject.isEmpty
//                } else {
//                    user.usesCompanyLogin = false
//                }
//            }

//            if payload.isDeleted == true {
//                user.markAccountAsDeleted(at: Date())
//            }

            if let name = event.name, !user.isAccountDeleted {
                user.name = name
            }

//            if (payload.updatedKeys.contains(.phone) || authoritative) && !user.isAccountDeleted {
//                user.phoneNumber = payload.phone?.removingExtremeCombiningCharacters
//            }

            if let email = event.email, !user.isAccountDeleted {
                user.emailAddress = email.removingExtremeCombiningCharacters
            }

            if let handle = event.handle, !user.isAccountDeleted {
                user.handle = handle
            }

//            if payload.managedBy != nil || authoritative {
//                user.managedBy = payload.managedBy
//            }

            if let accentColor = event.accentColorID, 
               let accentColorValue = AccentColor(rawValue: Int16(accentColor)) {
                user.accentColor = accentColorValue
            }

//            if let expiresAt = payload.expiresAt {
//                user.expiresAt = expiresAt
//            }

            updateAssets(
                from: event,
                for: user
            )

            if let supportedProtocols = event.supportedProtocols {
                user.supportedProtocols = supportedProtocols.toDomainModel()
            } else {
                user.supportedProtocols = [.proteus]
            }

            user.isPendingMetadataRefresh = false
            user.updatePotentialGapSystemMessagesIfNeeded()
        }
    }
    
    private func updateAssets(
        from event: UserUpdateEvent,
        for user: ZMUser
    ) {
        let assetKeys: Set<String> = [
            ZMUser.previewProfileAssetIdentifierKey,
            ZMUser.completeProfileAssetIdentifierKey
        ]
        
        guard !user.hasLocalModifications(forKeys: assetKeys) else {
            return
        }

        let validAssets = event.assets?.filter(\.key.isValidAssetID)
        
        let previewAssetKey = validAssets?
            .first(where: { $0.size == .preview })
            .map(\.key)
        
        let completeAssetKey = validAssets?
            .first(where: { $0.size == .complete })
            .map(\.key)

        if let previewAssetKey {
            user.previewProfileAssetIdentifier = previewAssetKey
        }

        if let completeAssetKey {
            user.completeProfileAssetIdentifier = completeAssetKey
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
