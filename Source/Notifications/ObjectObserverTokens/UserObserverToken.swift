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
import ZMCSystem

extension ZMUser : ObjectInSnapshot {
    
    public var observableKeys : [String] {
        return ["name", "displayName", "accentColorValue", "imageMediumData", "imageSmallProfileData","emailAddress", "phoneNumber", "canBeConnected", "isConnected", "isPendingApprovalByOtherUser", "isPendingApprovalBySelfUser", "clients", "handle"]
    }

    public func keyPathsForValuesAffectingValueForKey(forKey key: String) -> KeySet {
        return KeySet(ZMUser.keyPathsForValuesAffectingValue(forKey: key))
    }
}


@objc open class UserChangeInfo : ObjectChangeInfo {

    public required init(object: NSObject) {
        self.user = object as! ZMBareUser
        super.init(object: object)
    }

    open var nameChanged : Bool {
        return !Set(arrayLiteral: "name", "displayName").isDisjoint(with: changedKeysAndOldValues.keys)
    }
    
    open var accentColorValueChanged : Bool {
        return changedKeysAndOldValues.keys.contains("accentColorValue")
    }

    open var imageMediumDataChanged : Bool {
        return changedKeysAndOldValues.keys.contains("imageMediumData")
    }

    open var imageSmallProfileDataChanged : Bool {
        return changedKeysAndOldValues.keys.contains("imageSmallProfileData")
    }

    open var profileInformationChanged : Bool {
        return !Set(arrayLiteral: "emailAddress", "phoneNumber").isDisjoint(with: changedKeysAndOldValues.keys)
    }

    open var connectionStateChanged : Bool {
        return !Set(arrayLiteral: "isConnected", "canBeConnected", "isPendingApprovalByOtherUser", "isPendingApprovalBySelfUser").isDisjoint(with: changedKeysAndOldValues.keys)
    }

    open var trustLevelChanged : Bool {
        return userClientChangeInfo != nil
    }

    open var clientsChanged : Bool {
        return changedKeysAndOldValues.keys.contains("clients")
    }

    public var handleChanged : Bool {
        return changedKeysAndOldValues.keys.contains("handle")
    }


    open let user: ZMBareUser
    open var userClientChangeInfo : UserClientChangeInfo?

}

/// This is either ZMUser or ZMSearchUser
//private typealias ObservableUser = protocol<ObjectInSnapshot, ZMBareUser>


/*

user             -> UserObserverToken
ObjectInSnapshot -> ObjectObserverTokenContainer

*/


/// For a single user.
class GenericUserObserverToken<T : NSObject>: ObjectObserverTokenContainer where T: ObjectInSnapshot {

    typealias InnerTokenType = ObjectObserverToken<UserChangeInfo, GenericUserObserverToken<T>>

    fileprivate let observedUser: T?
    fileprivate weak var observer : ZMUserObserver?
    fileprivate weak var managedObjectContext: NSManagedObjectContext?
    fileprivate var clientTokens = [UserClient: UserClientObserverToken]()

    fileprivate static func objectDidChange(_ container: GenericUserObserverToken<T>, changeInfo: UserChangeInfo) {
        container.observer?.userDidChange(changeInfo)
    }

    init(observer: ZMUserObserver, user: T, managedObjectContext: NSManagedObjectContext, keyForDirectoryInUserInfo: String) {
        self.observer = observer
        self.managedObjectContext = managedObjectContext
        self.observedUser = user

        var changeHandler : (GenericUserObserverToken<T>, UserChangeInfo) -> Void = { _ in return }
        let innerToken = InnerTokenType.token(
            user,
            observableKeys: user.observableKeys,
            managedObjectContextObserver: managedObjectContext.globalManagedObjectContextObserver,
            changeHandler: { changeHandler($0, $1) }
        )
        
        super.init(object: user, token: innerToken)
        if let user = user as? ZMUser {
            // we initialy register observers for all of the users clients
            registerObserverForClients(user.clients)
        }
        
        // NB! The wrapper closure is created every time @c GenericUserObserverToken is created, but only the first one 
        // created is actually called, but for every container that been added.
        changeHandler = { [weak self] container, changeInfo in
            // clients might have been added or removed in the update, so we
            // need to add or remove observers for them accordingly
            self?.updateClientObserversIfNeeded(changeInfo)
            GenericUserObserverToken.objectDidChange(container, changeInfo: changeInfo)
        }
        innerToken.addContainer(self)
    }

    override func tearDown() {
        if let t = self.token as? InnerTokenType {
            t.removeContainer(self)
            if t.hasNoContainers {
                t.tearDown()
            }
        }
        removeObserverForClientTokens()
    }

    fileprivate func registerObserverForClients(_ clients: Set<UserClient>) {
        guard let managedObjectContext = managedObjectContext else { return }
        
        clients.forEach {
            clientTokens[$0] = UserClientObserverToken(observer: self, managedObjectContext: managedObjectContext, userClient: $0)
        }
    }

    fileprivate func removeObserverForClientTokens() {
        clientTokens.forEach { $0.1.tearDown() }
        clientTokens = [:]
    }

    fileprivate func updateClientObserversIfNeeded(_ changeInfo: UserChangeInfo) {
        guard let user = observedUser as? ZMUser , changeInfo.clientsChanged else { return }
        let observedClients = Set(clientTokens.map { $0.0 })
        let clients = user.clients ?? Set()
        
        let addedClients = clients.subtracting(observedClients)
        registerObserverForClients(addedClients)
        
        observedClients.subtracting(user.clients).forEach {
            clientTokens[$0]?.tearDown()
            clientTokens.removeValue(forKey: $0)
        }
    }
    
    func connectionDidChange(_ changedUsers: [ZMUser]) {
        guard let user = object as? ZMUser , changedUsers.index(of: user) != nil,
              let token = token as? InnerTokenType
        else { return }
        
        token.keysHaveChanged(["connection"])
    }

}

extension GenericUserObserverToken: UserClientObserver {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        guard let userChangeInfo = observedUser.map(UserChangeInfo.init)
        else { return }
        
        userChangeInfo.userClientChangeInfo = changeInfo
        (token as? InnerTokenType)?.notifyObservers(userChangeInfo)
    }
}


extension ObjectObserverTokenContainer  {
}

public func ==(lhs: ObjectObserverTokenContainer, rhs: ObjectObserverTokenContainer) -> Bool {
    return lhs === rhs
}


open class UserCollectionObserverToken: NSObject, ZMUserObserver  {
    var tokens : [UserObserverToken] = []
    weak var observer: ZMUserObserver?

    public init(observer: ZMUserObserver, users: [ZMBareUser], managedObjectContext:NSManagedObjectContext) {
        self.observer = observer
        super.init()
        users.forEach{
            if let token = managedObjectContext.globalManagedObjectContextObserver.addUserObserver(self, user:$0) as? UserObserverToken {
                tokens.append(token)
            }
        }
    }

    open func userDidChange(_ note: UserChangeInfo!) {
        observer?.userDidChange(note)
    }

    open func tearDown() {
        tokens.forEach{$0.tearDown()}
    }
}


class UserObserverToken : NSObject, ChangeNotifierToken {
    typealias Observer = ZMUserObserver
    typealias ChangeInfo = UserChangeInfo
    typealias GlobalObserver = GlobalUserObserver
    
    weak var observer : ZMUserObserver?
    weak var globalObserver : GlobalUserObserver?
    
    required init(observer: ZMUserObserver, globalObserver: GlobalUserObserver) {
        self.observer = observer
        self.globalObserver = globalObserver
        super.init()
    }
    
    func notifyObserver(_ note: UserChangeInfo) {
        observer?.userDidChange(note)
    }
    
    func tearDown() {
        globalObserver?.removeUserObserverForToken(self)
    }
}







