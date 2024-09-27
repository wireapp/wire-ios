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
import WireFoundation

// MARK: - UserProfilePayloadProcessing

// sourcery: AutoMockable
protocol UserProfilePayloadProcessing {
    func updateUserProfiles(
        from userProfiles: Payload.UserProfiles,
        in context: NSManagedObjectContext
    )
}

// MARK: - UserProfilePayloadProcessor

final class UserProfilePayloadProcessor: UserProfilePayloadProcessing {
    /// Update all user entities with the data from the user profiles.
    ///
    /// - parameter context: `NSManagedObjectContext` on which the update should be performed.
    func updateUserProfiles(
        from userProfiles: Payload.UserProfiles,
        in context: NSManagedObjectContext
    ) {
        for userProfile in userProfiles {
            guard
                let id = userProfile.id ?? userProfile.qualifiedID?.uuid,
                let user = ZMUser.fetch(with: id, domain: userProfile.qualifiedID?.domain, in: context)
            else {
                continue
            }

            updateUserProfile(
                from: userProfile,
                for: user
            )
        }
    }

    /// Update a user entity with the data from a user profile payload.
    ///
    /// A user profile payload comes in two variants: full and delta, a full update is
    /// used to initially sync the entity with the server state. After this the entity
    /// can be updated with delta updates, which only contain the fields which have changed.
    ///
    /// - parameter user: User entity which on which the update should be applied.
    /// - parameter authoritative: If **true** the update will be applied as if the update
    ///                            is a full update, any missing fields will be removed from
    ///                            the entity.

    func updateUserProfile(
        from payload: Payload.UserProfile,
        for user: ZMUser,
        authoritative: Bool = true
    ) {
        if let qualifiedID = payload.qualifiedID, BackendInfo.isFederationEnabled {
            precondition(user.remoteIdentifier == nil || user.remoteIdentifier == qualifiedID.uuid)
            precondition(user.domain == nil || user.domain == qualifiedID.domain)

            user.remoteIdentifier = qualifiedID.uuid
            user.domain = qualifiedID.domain
        } else if let id = payload.id {
            precondition(user.remoteIdentifier == nil || user.remoteIdentifier == id)
            user.remoteIdentifier = id
        }

        if let serviceID = payload.serviceID {
            user.serviceIdentifier = serviceID.id.transportString()
            user.providerIdentifier = serviceID.provider.transportString()
        }

        if payload.updatedKeys.contains(.teamID) || authoritative {
            user.teamIdentifier = payload.teamID
            user.createOrDeleteMembershipIfBelongingToTeam()
        }

        if payload.SSOID != nil || authoritative {
            if let subject = payload.SSOID?.subject {
                user.usesCompanyLogin = !subject.isEmpty
            } else {
                user.usesCompanyLogin = false
            }
        }

        if payload.isDeleted == true {
            user.markAccountAsDeleted(at: Date())
        }

        if (payload.name != nil || authoritative) && !user.isAccountDeleted {
            user.name = payload.name
        }

        if (payload.updatedKeys.contains(.phone) || authoritative) && !user.isAccountDeleted {
            user.phoneNumber = payload.phone?.removingExtremeCombiningCharacters
        }

        if (payload.updatedKeys.contains(.email) || authoritative) && !user.isAccountDeleted {
            user.emailAddress = payload.email?.removingExtremeCombiningCharacters
        }

        if (payload.handle != nil || authoritative) && !user.isAccountDeleted {
            user.handle = payload.handle
        }

        if payload.managedBy != nil || authoritative {
            user.managedBy = payload.managedBy
        }

        if let accentColor = payload.accentColor, let accentColorValue = AccentColor(rawValue: Int16(accentColor)) {
            user.accentColor = accentColorValue
        }

        if let expiresAt = payload.expiresAt {
            user.expiresAt = expiresAt
        }

        updateAssets(
            from: payload,
            for: user,
            authoritative: authoritative
        )

        if let supportedProtocols = payload.supportedProtocols {
            user.supportedProtocols = Set(supportedProtocols.map(\.dataModelMessageProtocol))
        } else {
            user.supportedProtocols = [.proteus]
        }

        if authoritative {
            user.needsToBeUpdatedFromBackend = false
        }

        user.isPendingMetadataRefresh = false
        user.updatePotentialGapSystemMessagesIfNeeded()
    }

    func updateAssets(
        from payload: Payload.UserProfile,
        for user: ZMUser,
        authoritative: Bool = true
    ) {
        let assetKeys: Set<String> = [
            ZMUser.previewProfileAssetIdentifierKey,
            ZMUser.completeProfileAssetIdentifierKey,
        ]
        guard !user.hasLocalModifications(forKeys: assetKeys) else {
            return
        }

        let validAssets = payload.assets?.filter(\.key.isValidAssetID)
        let previewAssetKey = validAssets?.first(where: { $0.size == .preview }).map(\.key)
        let completeAssetKey = validAssets?.first(where: { $0.size == .complete }).map(\.key)

        if previewAssetKey != nil || authoritative {
            user.previewProfileAssetIdentifier = previewAssetKey
        }

        if completeAssetKey != nil || authoritative {
            user.completeProfileAssetIdentifier = completeAssetKey
        }
    }
}

extension Payload.UserProfile.MessageProtocol {
    fileprivate var dataModelMessageProtocol: MessageProtocol {
        switch self {
        case .proteus:
            .proteus

        case .mls:
            .mls
        }
    }
}
