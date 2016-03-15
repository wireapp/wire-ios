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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMCSystem

extension ZMUser : ObjectInSnapshot {

    public var keysToChangeInfoMap : KeyToKeyTransformation { return KeyToKeyTransformation(mapping: [
        KeyPath.keyPathForString("name") : .Default,
        KeyPath.keyPathForString("displayName") : .Custom(KeyPath.keyPathForString("nameChanged")),
        KeyPath.keyPathForString("accentColorValue") : .Default,
        KeyPath.keyPathForString("imageMediumData") : .Default,
        KeyPath.keyPathForString("imageSmallProfileData") : .Default,
        KeyPath.keyPathForString("emailAddress") : .Custom(KeyPath.keyPathForString("profileInformationChanged")),
        KeyPath.keyPathForString("phoneNumber") : .Custom(KeyPath.keyPathForString("profileInformationChanged")),
        KeyPath.keyPathForString("canBeConnected") : .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("isConnected") : .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("connectionRequestMessage") : .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("isPendingApprovalByOtherUser") : .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("isPendingApprovalBySelfUser") : .Custom(KeyPath.keyPathForString("connectionStateChanged")),
        KeyPath.keyPathForString("clients") : .Custom(KeyPath.keyPathForString("clientsChanged")),
        ])
    }

    public func keyPathsForValuesAffectingValueForKey(key: String) -> KeySet {
        return KeySet(ZMUser.keyPathsForValuesAffectingValueForKey(key))
    }
}


@objc public class UserChangeInfo : ObjectChangeInfo {

    public required init(object: NSObject) {
        self.user = object as! ZMBareUser
        super.init(object: object)
    }

    public var nameChanged = false
    public var accentColorValueChanged = false
    public var imageMediumDataChanged = false
    public var imageSmallProfileDataChanged = false
    public var profileInformationChanged = false
    public var connectionStateChanged = false
    public var trustLevelChanged = false
    public var clientsChanged = false

    public let user: ZMBareUser
    public var userClientChangeInfo : UserClientChangeInfo? {
        didSet {
            trustLevelChanged = true
        }
    }
}

/// This is either ZMUser or ZMSearchUser
//private typealias ObservableUser = protocol<ObjectInSnapshot, ZMBareUser>


/*

user             -> UserObserverToken
ObjectInSnapshot -> ObjectObserverTokenContainer

*/


/// For a single user.
class GenericUserObserverToken<T : NSObject where T: ObjectInSnapshot>: ObjectObserverTokenContainer {

    typealias InnerTokenType = ObjectObserverToken<UserChangeInfo, GenericUserObserverToken<T>>
    typealias Directory = ObserverTokenDirectory<UserChangeInfo, GenericUserObserverToken<T>, T>

    private let observedUser: T?
    private weak var observer : ZMUserObserver?
    private let managedObjectContext: NSManagedObjectContext
    private let keyForDirectoryInUserInfo : String
    private var clientTokens = [UserClient: UserClientObserverToken]()

    private static func objectDidChange(container: GenericUserObserverToken<T>, changeInfo: UserChangeInfo) {
        container.observer?.userDidChange(changeInfo)
    }

    private init(observer: ZMUserObserver, user: T, managedObjectContext: NSManagedObjectContext, keyForDirectoryInUserInfo: String) {
        self.observer = observer
        self.managedObjectContext = managedObjectContext
        self.keyForDirectoryInUserInfo = keyForDirectoryInUserInfo
        self.observedUser = user

        var wrapper : (GenericUserObserverToken<T>, UserChangeInfo) -> Void = { _ in return }
        let directory = Directory.directoryInManagedObjectContext(managedObjectContext, keyForDirectoryInUserInfo: keyForDirectoryInUserInfo)
        let innerToken = directory.tokenForObject(user, createBlock: {
            let token = InnerTokenType.tokenWithContainers(
                user,
                keyToKeyTransformation: user.keysToChangeInfoMap,
                keysThatNeedPreviousValue: KeyToKeyTransformation(mapping: [:]),
                managedObjectContextObserver: managedObjectContext.globalManagedObjectContextObserver,
                observer: { wrapper($0, $1) }
            )
            return token
        })

        super.init(object: user, token: innerToken)
        if let user = user as? ZMUser {
            // we initialy register observers for all of the users clients
            registerObserverForClients(user.clients)
        }
        
        // NB! The wrapper closure is created every time @c GenericUserObserverToken is created, but only the first one 
        // created is actually called, but for every container that been added.
        wrapper = { [weak self] container, changeInfo in
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
                let directory = Directory.directoryInManagedObjectContext(self.managedObjectContext, keyForDirectoryInUserInfo: self.keyForDirectoryInUserInfo)
                directory.removeTokenForObject(self.object as! NSObject)
            }
        }
        removeObserverForClientTokens()
    }

    private func registerObserverForClients(clients: Set<UserClient>) {
        clients.forEach {
            clientTokens[$0] = UserClientObserverToken(observer: self, managedObjectContext: self.managedObjectContext, userClient: $0)
        }
    }

    private func removeObserverForClientTokens() {
        clientTokens.forEach { $0.1.tearDown() }
    }

    private func updateClientObserversIfNeeded(changeInfo: UserChangeInfo) {
        guard let user = observedUser as? ZMUser where changeInfo.clientsChanged else { return }
        let observedClients = Set(clientTokens.map { $0.0 })
        let addedClients = user.clients.subtract(observedClients)
        registerObserverForClients(addedClients)
        
        observedClients.subtract(user.clients).forEach {
            clientTokens[$0]?.tearDown()
            clientTokens.removeValueForKey($0)
        }
    }

}

extension GenericUserObserverToken: UserClientObserver {
    func userClientDidChange(changeInfo: UserClientChangeInfo) {
        guard let userChangeInfo = observedUser.map(UserChangeInfo.init) else { return }
        userChangeInfo.userClientChangeInfo = changeInfo
        let directory = Directory.directoryInManagedObjectContext(managedObjectContext, keyForDirectoryInUserInfo: keyForDirectoryInUserInfo)
        // For optimization tokens are beeing reused and stored in the directory, if we manually
        // want to notify all observers of an object, we need to grab the token and tell it to notify all observers
        guard let user = observedUser, token = directory.existingTokenForObject(user) else { return }
        token.notifyObservers(userChangeInfo)
    }
}


extension ObjectObserverTokenContainer  {
}

public func ==(lhs: ObjectObserverTokenContainer, rhs: ObjectObserverTokenContainer) -> Bool {
    return lhs === rhs
}


public class GenericUserCollectionObserverToken<T: NSObject where T: ObjectInSnapshot> : NSObject {

    private weak var observer : ZMUserObserver?
    private var tokens : [GenericUserObserverToken<T>] = []

    init(observer: ZMUserObserver, users: [T], managedObjectContext: NSManagedObjectContext, keyForDirectoryInUserInfo: String) {
        self.observer = observer
        self.tokens = users.map{GenericUserObserverToken<T>(observer:observer, user:$0, managedObjectContext:managedObjectContext, keyForDirectoryInUserInfo:keyForDirectoryInUserInfo)}
    }

    public func tearDown() {
        for t in self.tokens {
            t.tearDown()
        }
    }
}


@objc public class UserCollectionObserverToken: NSObject  {

    var token : AnyObject?

    public init(observer: ZMUserObserver, users: [ZMBareUser], managedObjectContext:NSManagedObjectContext) {
        if let searchUsers = users as? [ZMSearchUser] {
            self.token = GenericUserCollectionObserverToken(observer: observer, users:searchUsers, managedObjectContext:managedObjectContext, keyForDirectoryInUserInfo:"searchUser")
        } else {
            self.token = GenericUserCollectionObserverToken(observer: observer, users:users as! [ZMUser], managedObjectContext:managedObjectContext, keyForDirectoryInUserInfo:"user")
        }
    }


    public func tearDown() {
        if let token = self.token as? GenericUserCollectionObserverToken<ZMUser> {
            token.tearDown()
        } else if let token = self.token as? GenericUserCollectionObserverToken<ZMSearchUser> {
            token.tearDown()
        }
    }
}




