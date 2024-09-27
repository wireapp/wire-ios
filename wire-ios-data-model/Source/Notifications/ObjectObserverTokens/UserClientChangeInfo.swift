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

extension UserClient {
    override public var description: String {
        "Client: \(String(describing: sessionIdentifier?.rawValue)), user name: \(String(describing: user?.name)) email: \(String(describing: user?.emailAddress)) platform: \(String(describing: deviceClass)), label: \(String(describing: label)), model: \(String(describing: model))"
    }
}

// MARK: - UserClient + ObjectInSnapshot

extension UserClient: ObjectInSnapshot {
    public static var observableKeys: Set<String> {
        Set([
            #keyPath(UserClient.trustedByClients),
            #keyPath(UserClient.ignoredByClients),
            #keyPath(UserClient.needsToNotifyUser),
            #keyPath(UserClient.needsToNotifyOtherUserAboutSessionReset),
        ])
    }

    public var notificationName: Notification.Name {
        .UserClientChange
    }
}

// MARK: - UserClientChangeInfoKey

public enum UserClientChangeInfoKey: String {
    case TrustedByClientsChanged = "trustedByClientsChanged"
    case IgnoredByClientsChanged = "ignoredByClientsChanged"
    case FingerprintChanged = "fingerprintChanged"
}

// MARK: - UserClientChangeInfo

@objcMembers
open class UserClientChangeInfo: ObjectChangeInfo {
    public required init(object: NSObject) {
        self.userClient = object as! UserClient
        super.init(object: object)
    }

    open var trustedByClientsChanged: Bool {
        changedKeysContain(keys: #keyPath(UserClient.trustedByClients))
    }

    open var ignoredByClientsChanged: Bool {
        changedKeysContain(keys: #keyPath(UserClient.ignoredByClients))
    }

    open var needsToNotifyUserChanged: Bool {
        changedKeysContain(keys: #keyPath(UserClient.needsToNotifyUser))
    }

    open var sessionHasBeenReset: Bool {
        changedKeysContain(keys: #keyPath(UserClient.needsToNotifyOtherUserAboutSessionReset)) &&
            userClient.needsToNotifyOtherUserAboutSessionReset == false
    }

    public let userClient: UserClient

    static func changeInfo(for client: UserClient, changes: Changes) -> UserClientChangeInfo? {
        UserClientChangeInfo(object: client, changes: changes)
    }
}

// MARK: - UserClientObserver

@objc
public protocol UserClientObserver: NSObjectProtocol {
    func userClientDidChange(_ changeInfo: UserClientChangeInfo)
}

extension UserClientChangeInfo {
    /// Adds an observer for the specified userclient
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forClient:)
    public static func add(observer: UserClientObserver, for client: UserClient) -> NSObjectProtocol? {
        guard let managedObjectContext = client.managedObjectContext else {
            return nil
        }
        return ManagedObjectObserverToken(
            name: .UserClientChange,
            managedObjectContext: managedObjectContext,
            object: client
        ) { [weak observer] note in
            guard let observer,
                  let changeInfo = note.changeInfo as? UserClientChangeInfo
            else { return }

            observer.userClientDidChange(changeInfo)
        }
    }
}
