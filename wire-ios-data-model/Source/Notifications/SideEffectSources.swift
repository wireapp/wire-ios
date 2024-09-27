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

typealias ObjectAndChanges = [ZMManagedObject: Changes]

// MARK: - SideEffectSource

protocol SideEffectSource {
    /// Returns a map of objects and keys that are affected by an update and it's resulting changedValues mapped by
    /// classIdentifier
    /// [classIdentifier : [affectedObject: changedKeys]]
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges

    /// Returns a map of objects and keys that are affected by an insert or deletion mapped by classIdentifier
    /// [classIdentifier : [affectedObject: changedKeys]]
    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges
}

extension ZMManagedObject {
    /// Returns a map of [classIdentifier : [affectedObject: changedKeys]]
    func byInsertOrDeletionAffectedKeys(
        for object: ZMManagedObject?,
        keyStore: DependencyKeyStore,
        affectedKey: String
    ) -> ObjectAndChanges {
        guard let object else { return [:] }
        let classIdentifier = type(of: object).entityName()
        return [object: Changes(changedKeys: keyStore.observableKeysAffectedByValue(classIdentifier, key: affectedKey))]
    }

    /// Returns a map of [classIdentifier : [affectedObject: changedKeys]]
    func byUpdateAffectedKeys(
        for object: ZMManagedObject?,
        knownKeys: Set<String>,
        keyStore: DependencyKeyStore,
        originalChangeKey: String? = nil,
        keyMapping: (String) -> String
    ) -> ObjectAndChanges {
        guard let object else { return [:] }
        let classIdentifier = type(of: object).entityName()

        var changes = changedValues()

        guard !changes.isEmpty || !knownKeys.isEmpty else {
            return [:]
        }

        let allKeys = knownKeys.union(changes.keys)
        let mappedKeys: [String] = Array(allKeys).map(keyMapping)

        let keys: Set<String> = mappedKeys
            .map {
                keyStore.observableKeysAffectedByValue(classIdentifier, key: $0)
            }
            .reduce(into: .init()) { partialResult, set in
                partialResult.formUnion(set)
            }

        guard !keys.isEmpty || originalChangeKey != nil else {
            return [:]
        }

        var originalChanges = [String: NSObject?]()
        if let originalChangeKey {
            let requiredKeys = keyStore.requiredKeysForIncludingRawChanges(classIdentifier: classIdentifier, for: self)
            for knownKey in knownKeys {
                if changes[knownKey] == nil {
                    changes[knownKey] = .none as NSObject?
                }
            }
            if requiredKeys.isEmpty || !requiredKeys.isDisjoint(with: changes.keys) {
                originalChanges = [originalChangeKey: [self: changes] as NSObject?]
            }
        }

        return [object: Changes(changedKeys: keys, originalChanges: originalChanges)]
    }
}

// MARK: - ZMUser + SideEffectSource

extension ZMUser: SideEffectSource {
    var allConversations: [ZMConversation] {
        var conversations = participantRoles.compactMap(\.conversation)
        if let oneOnOneConversation {
            conversations.append(oneOnOneConversation)
        }
        return conversations
    }

    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        let changes = changedValues()
        guard !changes.isEmpty || !knownKeys.isEmpty else { return [:] }

        let allKeys = knownKeys.union(changes.keys)

        let conversations = allConversations
        guard !conversations.isEmpty else { return  [:] }

        return conversationChanges(
            changedKeys: allKeys,
            conversations: conversations,
            keyStore: keyStore
        )
    }

    func conversationChanges(
        changedKeys: Set<String>,
        conversations: [ZMConversation],
        keyStore: DependencyKeyStore
    ) -> ObjectAndChanges {
        var affectedObjects = [ZMManagedObject: Changes]()
        let classIdentifier = ZMConversation.entityName()

        // Get all the changed keys, including the ones in the user that are affected by this change
        let allChangedKeys = changedKeys.reduce(into: Set<String>()) { keys, changedKey in
            keys.formUnion(keyStore.observableKeysAffectedByValue(ZMUser.entityName(), key: changedKey))
        }

        let otherPartKeys = allChangedKeys.map { "\(#keyPath(ZMConversation.participantRoles.user)).\($0)" }
        let selfUserKeys = allChangedKeys.map { "\(#keyPath(ZMConversation.oneOnOneUser)).\($0)" }
        let mappedKeys = otherPartKeys + selfUserKeys
        var keys: Set<String> = mappedKeys
            .map { keyStore.observableKeysAffectedByValue(classIdentifier, key: $0) }
            .reduce(into: .init()) { partialResult, set in
                partialResult.formUnion(set)
            }

        for conversation in conversations {
            if conversation.allUsersTrusted {
                keys.insert(SecurityLevelKey)
            }
            if !keys.isEmpty {
                affectedObjects[conversation] = Changes(changedKeys: keys)
            }
        }
        return affectedObjects
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        let conversations = allConversations
        guard !conversations.isEmpty else { return  [:] }

        let classIdentifier = ZMConversation.entityName()
        let affectedKeys = keyStore.observableKeysAffectedByValue(
            classIdentifier,
            key: #keyPath(ZMConversation.localParticipantRoles)
        )

        var dictionary = [ZMConversation: Changes]()
        for conversation in conversations {
            dictionary.updateValue(Changes(changedKeys: affectedKeys), forKey: conversation)
        }
        return dictionary
    }
}

// MARK: - ParticipantRole + SideEffectSource

extension ParticipantRole: SideEffectSource {
    func affectedObjectsAndKeys(
        keyStore: DependencyKeyStore,
        knownKeys: Set<String>
    ) -> ObjectAndChanges {
        let keyMapping: ((String) -> String) = {
            "\(#keyPath(ZMConversation.participantRoles)).\($0)"
        }

        return byUpdateAffectedKeys(
            for: conversation,
            knownKeys: knownKeys,
            keyStore: keyStore,
            keyMapping: keyMapping
        )
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        // delete a ParticipantRole should affects conversation's participants
        byInsertOrDeletionAffectedKeys(
            for: conversation,
            keyStore: keyStore,
            affectedKey: #keyPath(ZMConversation.participantRoles)
        )
    }
}

// MARK: - ZMMessage + SideEffectSource

extension ZMMessage: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        [:]
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(
            for: conversation,
            keyStore: keyStore,
            affectedKey: #keyPath(ZMConversation.allMessages)
        )
    }
}

// MARK: - ZMConnection + SideEffectSource

extension ZMConnection: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        let conversationChanges = byUpdateAffectedKeys(
            for: to?.oneOnOneConversation,
            knownKeys: knownKeys,
            keyStore: keyStore,
            keyMapping: { "\(#keyPath(ZMConversation.oneOnOneUser.connection)).\($0)" }
        )

        let userChanges = byUpdateAffectedKeys(
            for: to,
            knownKeys: knownKeys,
            keyStore: keyStore,
            keyMapping: { "\(#keyPath(ZMUser.connection)).\($0)" }
        )

        return conversationChanges.merging(userChanges) { _, new in new }
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(
            for: to?.oneOnOneConversation,
            keyStore: keyStore,
            affectedKey: #keyPath(ZMConversation.oneOnOneUser.connection)
        )
    }
}

// MARK: - UserClient + SideEffectSource

extension UserClient: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        byUpdateAffectedKeys(
            for: user,
            knownKeys: knownKeys,
            keyStore: keyStore,
            originalChangeKey: "clientChanges",
            keyMapping: { "\(#keyPath(ZMUser.clients)).\($0)" }
        )
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(for: user, keyStore: keyStore, affectedKey: #keyPath(ZMUser.clients))
    }
}

// MARK: - Reaction + SideEffectSource

extension Reaction: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        byUpdateAffectedKeys(
            for: message,
            knownKeys: knownKeys,
            keyStore: keyStore,
            originalChangeKey: "reactionChanges",
            keyMapping: { "\(#keyPath(ZMMessage.reactions)).\($0)" }
        )
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(for: message, keyStore: keyStore, affectedKey: #keyPath(ZMMessage.reactions))
    }
}

// MARK: - ButtonState + SideEffectSource

extension ButtonState: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        byUpdateAffectedKeys(
            for: message,
            knownKeys: knownKeys,
            keyStore: keyStore,
            originalChangeKey: MessageChangeInfo.ButtonStateChangeInfoKey,
            keyMapping: { "\(#keyPath(ZMClientMessage.buttonStates)).\($0)" }
        )
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(
            for: message,
            keyStore: keyStore,
            affectedKey: #keyPath(ZMClientMessage.buttonStates)
        )
    }
}

// MARK: - ZMGenericMessageData + SideEffectSource

extension ZMGenericMessageData: SideEffectSource {
    func affectedObjectsAndKeys(keyStore: DependencyKeyStore, knownKeys: Set<String>) -> ObjectAndChanges {
        byUpdateAffectedKeys(
            for: message ?? asset,
            knownKeys: knownKeys,
            keyStore: keyStore,
            keyMapping: { "\(#keyPath(ZMClientMessage.dataSet)).\($0)" }
        )
    }

    func affectedObjectsForInsertionOrDeletion(keyStore: DependencyKeyStore) -> ObjectAndChanges {
        byInsertOrDeletionAffectedKeys(
            for: message ?? asset,
            keyStore: keyStore,
            affectedKey: #keyPath(ZMClientMessage.dataSet)
        )
    }
}
