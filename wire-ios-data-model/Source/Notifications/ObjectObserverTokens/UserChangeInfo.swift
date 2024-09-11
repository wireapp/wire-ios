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
import WireSystem

protocol ObjectInSnapshot {
    static var observableKeys: Set<String> { get }
    var notificationName: Notification.Name { get }
}

extension ZMUser: ObjectInSnapshot {
    public static var observableKeys: Set<String> {
        [
            #keyPath(ZMUser.name),
            #keyPath(ZMUser.accentColorValue),
            #keyPath(ZMUser.imageMediumData),
            #keyPath(ZMUser.imageSmallProfileData),
            #keyPath(ZMUser.previewProfileAssetIdentifier),
            #keyPath(ZMUser.completeProfileAssetIdentifier),
            #keyPath(ZMUser.emailAddress),
            #keyPath(ZMUser.phoneNumber),
            #keyPath(ZMUser.canBeConnected),
            #keyPath(ZMUser.isConnected),
            #keyPath(ZMUser.isPendingApprovalByOtherUser),
            #keyPath(ZMUser.isPendingApprovalBySelfUser),
            #keyPath(ZMUser.clients),
            #keyPath(ZMUser.handle),
            #keyPath(ZMUser.team),
            #keyPath(ZMUser.availability),
            #keyPath(ZMUser.readReceiptsEnabled),
            #keyPath(ZMUser.readReceiptsEnabledChangedRemotely),
            ZMUserKeys.RichProfile,
            #keyPath(ZMUser.isServiceUser),
            #keyPath(ZMUser.serviceIdentifier),
            #keyPath(ZMUser.providerIdentifier),
            ZMUserKeys.legalHoldRequest,
            #keyPath(ZMUser.isUnderLegalHold),
            #keyPath(ZMUser.analyticsIdentifier),
        ]
    }

    public var notificationName: Notification.Name {
        .UserChange
    }
}

@objcMembers
open class UserChangeInfo: ObjectChangeInfo {
    static let UserClientChangeInfoKey = "clientChanges"

    static func changeInfo(for user: ZMUser, changes: Changes) -> UserChangeInfo? {
        var originalChanges = changes.originalChanges
        let clientChanges = originalChanges.removeValue(forKey: UserClientChangeInfoKey) as? [NSObject: [String: Any]]

        if let clientChanges {
            var userClientChangeInfos = [UserClientChangeInfo]()
            clientChanges.forEach {
                let changeInfo = UserClientChangeInfo(object: $0)
                changeInfo.changedKeys = Set($1.keys)
                userClientChangeInfos.append(changeInfo)
            }
            originalChanges[UserClientChangeInfoKey] = userClientChangeInfos as NSObject?
        }

        let modifiedChanges = changes.merged(with: Changes(originalChanges: originalChanges))
        return UserChangeInfo(object: user, changes: modifiedChanges)
    }

    public required init(object: NSObject) {
        self.user = object as! UserType
        super.init(object: object)
    }

    open var nameChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.name))
    }

    open var accentColorValueChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.accentColorValue))
    }

    open var imageMediumDataChanged: Bool {
        changedKeysContain(keys: #keyPath(UserType.completeImageData), #keyPath(ZMUser.completeProfileAssetIdentifier))
    }

    open var imageSmallProfileDataChanged: Bool {
        changedKeysContain(keys: #keyPath(UserType.previewImageData), #keyPath(ZMUser.previewProfileAssetIdentifier))
    }

    open var profileInformationChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.emailAddress), #keyPath(ZMUser.phoneNumber))
    }

    open var connectionStateChanged: Bool {
        changedKeysContain(
            keys: #keyPath(ZMUser.isConnected),
            #keyPath(ZMUser.canBeConnected),
            #keyPath(ZMUser.isPendingApprovalByOtherUser),
            #keyPath(ZMUser.isPendingApprovalBySelfUser)
        )
    }

    open var trustLevelChanged: Bool {
        !userClientChangeInfos.isEmpty
    }

    open var clientsChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.clients))
    }

    public var handleChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.handle))
    }

    public var teamsChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.team))
    }

    public var availabilityChanged: Bool {
        changedKeysContain(keys: #keyPath(ZMUser.availability))
    }

    public var readReceiptsEnabledChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.readReceiptsEnabled))
    }

    public var readReceiptsEnabledChangedRemotelyChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.readReceiptsEnabledChangedRemotely))
    }

    public var richProfileChanged: Bool {
        changedKeys.contains(ZMUserKeys.RichProfile)
    }

    public var legalHoldStatusChanged: Bool {
        !changedKeys.isDisjoint(with: ZMUser.keysAffectingLegalHoldStatus())
    }

    public var isUnderLegalHoldChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.isUnderLegalHold))
    }

    public var roleChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.participantRoles))
    }

    public var analyticsIdentifierChanged: Bool {
        changedKeys.contains(#keyPath(ZMUser.analyticsIdentifier))
    }

    public let user: UserType
    open var userClientChangeInfos: [UserClientChangeInfo] {
        changeInfos[UserChangeInfo.UserClientChangeInfoKey] as? [UserClientChangeInfo] ?? []
    }
}

extension UserChangeInfo {
    // MARK: Registering UserType

    /// Adds an observer for a user conforming to UserType. You must hold on to the token and use it to unregister.
    ///
    @objc(addObserver:forUser:inManagedObjectContext:)
    public static func add(
        observer: UserObserving,
        for user: UserType,
        in managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol? {
        if let user = user as? ZMSearchUser {
            return add(searchUserObserver: observer, for: user, in: managedObjectContext)
        } else if let user = user as? ZMUser {
            return add(userObserver: observer, for: user, in: managedObjectContext)
        }

        return nil
    }

    // MARK: Registering SearchUserObservers

    /// Adds an observer for all ZMSearchUsers in the given context. You must hold on to the token and use it to
    /// unregister.
    ///
    public static func add(
        searchUserObserver observer: UserObserving,
        in managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        add(searchUserObserver: observer, for: nil, in: managedObjectContext)
    }

    /// Adds an observer for the searchUser if one specified or to all ZMSearchUser is none is specified. You must
    /// hold on to the token and use it to unregister.
    ///
    private static func add(
        searchUserObserver observer: UserObserving,
        for user: ZMSearchUser?,
        in managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .SearchUserChange,
            managedObjectContext: managedObjectContext,
            object: user
        ) { [weak observer] note in
            guard
                let observer,
                let changeInfo = note.changeInfo as? UserChangeInfo
            else {
                return
            }

            observer.userDidChange(changeInfo)
        }
    }

    // MARK: Registering UserObservers

    /// Adds an observer for all ZMUsers in the given context. You must hold on to the token and use it to unregister.
    ///
    public static func add(
        userObserver observer: UserObserving,
        in managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        add(userObserver: observer, for: nil, in: managedObjectContext)
    }

    /// Adds an observer for the user if one specified or to all ZMUsers is none is specified. You must hold on to
    /// the token and use it to unregister.
    ///
    private static func add(
        userObserver observer: UserObserving,
        for user: ZMUser?,
        in managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .UserChange,
            managedObjectContext: managedObjectContext,
            object: user
        ) { [weak observer] note in
            guard
                let observer,
                let changeInfo = note.changeInfo as? UserChangeInfo
            else {
                return
            }

            observer.userDidChange(changeInfo)
        }
    }
}
