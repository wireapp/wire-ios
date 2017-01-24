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

@objc public protocol UserClientObserverOpaqueToken: NSObjectProtocol {
}

public protocol UserClientObserver: NSObjectProtocol {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo)
}

// MARK: - Observing
extension UserClient {
    
    public func addObserver(_ observer: UserClientObserver) -> UserClientObserverOpaqueToken? {
        guard let managedObjectContext = self.managedObjectContext
            else { return .none }
        
        return UserClientObserverToken(observer: observer, managedObjectContext: managedObjectContext, userClient: self)
    }
    
    public static func removeObserverForUserClientToken(_ token: UserClientObserverOpaqueToken) {
        if let token = token as? UserClientObserverToken {
            token.tearDown()
        }
    }
}

// MARK: - Observing
extension UserClient {
    public override var description: String {
        return "Client: \(sessionIdentifier), user name: \(user?.name) email: \(user?.emailAddress) platform: \(deviceClass), label: \(label), model: \(model)"
    }
    
}

extension UserClient: ObjectInSnapshot {

    public var observableKeys : [String] {
        return [ZMUserClientTrusted_ByKey, ZMUserClientIgnored_ByKey, ZMUserClientNeedsToNotifyUserKey, ZMUserClientFingerprintKey]
    }

    public func keyPathsForValuesAffectingValueForKey(_ key: String) -> KeySet {
        return KeySet(UserClient.keyPathsForValuesAffectingValue(forKey: key))
    }
}

public enum UserClientChangeInfoKey: String {
    case TrustedByClientsChanged = "trustedByClientsChanged"
    case IgnoredByClientsChanged = "ignoredByClientsChanged"
    case FingerprintChanged = "fingerprintChanged"
}

@objc open class UserClientChangeInfo : ObjectChangeInfo {

    public required init(object: NSObject) {
        self.userClient = object as! UserClient
        super.init(object: object)
    }

    open var trustedByClientsChanged : Bool {
        return changedKeysAndOldValues.keys.contains(ZMUserClientTrusted_ByKey)
    }
    open var ignoredByClientsChanged : Bool {
        return changedKeysAndOldValues.keys.contains(ZMUserClientIgnored_ByKey)
    }

    open var fingerprintChanged : Bool {
        return changedKeysAndOldValues.keys.contains(ZMUserClientNeedsToNotifyUserKey)
    }

    open var needsToNotifyUserChanged : Bool {
        return changedKeysAndOldValues.keys.contains(ZMUserClientFingerprintKey)
    }

    open let userClient: UserClient
}

public final class UserClientObserverToken: ObjectObserverTokenContainer, UserClientObserverOpaqueToken {

    typealias InnerTokenType = ObjectObserverToken<UserClientChangeInfo, UserClientObserverToken>
    typealias Directory = ObserverTokenDirectory<UserClientChangeInfo, UserClientObserverToken, UserClient>

    fileprivate weak var observer : UserClientObserver?
    fileprivate let managedObjectContext: NSManagedObjectContext

    public init(observer: UserClientObserver, managedObjectContext: NSManagedObjectContext, userClient: UserClient) {

        self.managedObjectContext = managedObjectContext
        var changeHandler : (UserClientObserverToken, UserClientChangeInfo) -> () = { _ in return }
        self.observer = observer
        
        let directory = Directory.directoryInManagedObjectContext(managedObjectContext, keyForDirectoryInUserInfo: "UserClient")

        let innerToken = directory.tokenForObject(userClient, createBlock: {
            let token = InnerTokenType.token(
                userClient,
                observableKeys: userClient.observableKeys,
                managedObjectContextObserver: userClient.managedObjectContext!.globalManagedObjectContextObserver,
                changeHandler: { changeHandler($0, $1) }
            )
            return token
        })
        super.init(object: userClient, token: innerToken)
        
        // NB! The wrapper closure is created every time @c UserClientObserverToken is created, but only the first one
        // created is actually called, but for every container that been added.
        changeHandler = { container, changeInfo in
            container.observer?.userClientDidChange(changeInfo)
        }
        
        innerToken.addContainer(self)
    }

    override public func tearDown() {
        if let t = self.token as? InnerTokenType {
            t.removeContainer(self)
            if t.hasNoContainers {
                t.tearDown()
                let directory = Directory.directoryInManagedObjectContext(self.managedObjectContext, keyForDirectoryInUserInfo: "UserClient")
                directory.removeTokenForObject(self.object as! NSObject)
            }
        }
    }
}
