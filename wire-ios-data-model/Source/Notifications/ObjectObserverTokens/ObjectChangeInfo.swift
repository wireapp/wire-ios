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

// MARK: Base class for observer / change info

public protocol ObjectChangeInfoProtocol: NSObjectProtocol {
    var changeInfos: [String: NSObject?] { get set }

    init(object: NSObject)

    func setValue(_ value: Any?, forKey key: String)

    func value(forKey key: String) -> Any?
}

open class ObjectChangeInfo: NSObject, ObjectChangeInfoProtocol {
    let object: NSObject

    open var changedKeys = Set<String>()
    open var changeInfos = [String: NSObject?]()

    var considerAllKeysChanged = false

    convenience init?(object: NSObject, changes: Changes) {
        guard changes.hasChangeInfo else { return nil }
        self.init(object: object)
        self.changedKeys = changes.changedKeys
        self.changeInfos = changes.originalChanges
        self.considerAllKeysChanged = changes.mayHaveUnknownChanges
    }

    public required init(object: NSObject) {
        self.object = object
    }

    func changedKeysContain(keys: String...) -> Bool {
        considerAllKeysChanged || !changedKeys.isDisjoint(with: keys)
    }

    var customDebugDescription: String {
        guard let managedObject = object as? NSManagedObject else {
            return "ChangeInfo for \(object) with changedKeys: \(changedKeys), changeInfos: \(changeInfos)"
        }

        return "ChangeInfo for \(managedObject.objectID) with changedKeys: \(changedKeys), changeInfos: \(changeInfos)"
    }
}

extension ObjectChangeInfo {
    static func changeInfo(for object: NSObject, changes: Changes) -> ObjectChangeInfo? {
        switch object {
        case let object as ZMConversation:  ConversationChangeInfo.changeInfo(for: object, changes: changes)
        case let object as ZMUser:          UserChangeInfo.changeInfo(for: object, changes: changes)
        case let object as ZMMessage:       MessageChangeInfo.changeInfo(for: object, changes: changes)
        case let object as UserClient:      UserClientChangeInfo.changeInfo(for: object, changes: changes)
        case let object as Team:            TeamChangeInfo.changeInfo(for: object, changes: changes)
        case let object as Label:           LabelChangeInfo.changeInfo(for: object, changes: changes)
        case let object as ParticipantRole: ParticipantRoleChangeInfo.changeInfo(for: object, changes: changes)
        default:
            nil
        }
    }
}
