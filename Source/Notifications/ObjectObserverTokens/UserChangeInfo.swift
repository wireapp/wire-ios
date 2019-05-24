//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
    static var observableKeys : Set<String> { get }
    var notificationName : Notification.Name { get }
}

extension ZMUser : ObjectInSnapshot {
    
    static public var observableKeys : Set<String> {
        return [
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
            #keyPath(ZMUser.isUnderLegalHold)
        ]
    }

    public var notificationName : Notification.Name {
        return .UserChange
    }
}


@objcMembers open class UserChangeInfo : ObjectChangeInfo {

    static let UserClientChangeInfoKey = "clientChanges"
    
    static func changeInfo(for user: ZMUser, changes: Changes) -> UserChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }

        var originalChanges = changes.originalChanges
        let clientChanges = originalChanges.removeValue(forKey: UserClientChangeInfoKey) as? [NSObject : [String : Any]]
        
        if let clientChanges = clientChanges {
            var userClientChangeInfos = [UserClientChangeInfo]()
            clientChanges.forEach {
                let changeInfo = UserClientChangeInfo(object: $0)
                changeInfo.changedKeys = Set($1.keys)
                userClientChangeInfos.append(changeInfo)
            }
            originalChanges[UserClientChangeInfoKey] = userClientChangeInfos as NSObject?
        }
        guard originalChanges.count > 0 || changes.changedKeys.count > 0 else { return nil }
        
        let changeInfo = UserChangeInfo(object: user)
        changeInfo.changeInfos = originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
    
    public required init(object: NSObject) {
        self.user = object as! UserType
        super.init(object: object)
    }

    open var nameChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.name))
    }
    
    open var accentColorValueChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.accentColorValue))
    }

    open var imageMediumDataChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserType.completeImageData), #keyPath(ZMUser.completeProfileAssetIdentifier))
    }

    open var imageSmallProfileDataChanged : Bool {
        return changedKeysContain(keys: #keyPath(UserType.previewImageData), #keyPath(ZMUser.previewProfileAssetIdentifier))
    }

    open var profileInformationChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.emailAddress), #keyPath(ZMUser.phoneNumber))
    }

    open var connectionStateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.isConnected),
                                  #keyPath(ZMUser.canBeConnected),
                                  #keyPath(ZMUser.isPendingApprovalByOtherUser),
                                  #keyPath(ZMUser.isPendingApprovalBySelfUser))
    }

    open var trustLevelChanged : Bool {
        return userClientChangeInfos.count != 0
    }

    open var clientsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.clients))
    }

    public var handleChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMUser.handle))
    }

    public var teamsChanged : Bool {
        return changedKeys.contains(#keyPath(ZMUser.team))
    }
    
    public var availabilityChanged : Bool {
        return changedKeys.contains(#keyPath(ZMUser.availability))
    }

    public var readReceiptsEnabledChanged : Bool {
        return changedKeys.contains(#keyPath(ZMUser.readReceiptsEnabled))
    }
    
    public var readReceiptsEnabledChangedRemotelyChanged : Bool {
        return changedKeys.contains(#keyPath(ZMUser.readReceiptsEnabledChangedRemotely))
    }
    
    public var richProfileChanged : Bool {
        return changedKeys.contains(ZMUserKeys.RichProfile)
    }

    public var legalHoldStatusChanged: Bool {
        return changedKeys.contains(#keyPath(ZMUser.isUnderLegalHold))
    }
    
    public let user: UserType
    open var userClientChangeInfos : [UserClientChangeInfo] {
        return changeInfos[UserChangeInfo.UserClientChangeInfoKey] as? [UserClientChangeInfo] ?? []
    }
}



@objc public protocol ZMUserObserver : NSObjectProtocol {
    func userDidChange(_ changeInfo: UserChangeInfo)
}


extension UserChangeInfo {

    // MARK: Registering UserObservers
    /// Adds an observer for the user if one specified or to all ZMUsers is none is specified
    /// You must hold on to the token and use it to unregister
    @objc(addUserObserver:forUser:managedObjectContext:)
    public static func add(userObserver observer: ZMUserObserver, for user: ZMUser?, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .UserChange, managedObjectContext: managedObjectContext, object: user)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? UserChangeInfo
                else { return }
            
            observer.userDidChange(changeInfo)
        }
    }
    
    // MARK: Registering SearchUserObservers
    /// Adds an observer for the searchUser if one specified or to all ZMSearchUser is none is specified
    /// You must hold on to the token and use it to unregister
    @objc(addSearchUserObserver:forSearchUser:managedObjectContext:)
    public static func add(searchUserObserver observer: ZMUserObserver,
                           for user: ZMSearchUser?,
                           managedObjectContext: NSManagedObjectContext
                           ) -> NSObjectProtocol
    {
        return ManagedObjectObserverToken(name: .SearchUserChange, managedObjectContext: managedObjectContext, object: user)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? UserChangeInfo
                else { return }
            
            observer.userDidChange(changeInfo)
        }
    }
    
    // MARK: Registering UserType
    /// Adds an observer for the ZMUser or ZMSearchUser
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forUser:managedObjectContext:)
    public static func add(observer: ZMUserObserver,
                           for user: UserType,
                           managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol?
    {
        if let user = user as? ZMSearchUser {
            return add(searchUserObserver: observer, for: user, managedObjectContext: managedObjectContext)
        }
        else if let user = user as? ZMUser {
            return add(userObserver: observer, for:user, managedObjectContext: managedObjectContext)
        }
        return nil
    }
}
