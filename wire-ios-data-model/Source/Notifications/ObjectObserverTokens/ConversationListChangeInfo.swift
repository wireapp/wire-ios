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

private var zmLog = ZMSLog(tag: "ConversationListObserverCenter")

extension ConversationList {
    func toOrderedSetState() -> OrderedSetState<ZMConversation> {
        OrderedSetState(array: items)
    }
}

// MARK: - ConversationListChangeInfo

@objcMembers
public final class ConversationListChangeInfo: NSObject, SetChangeInfoOwner {
    // MARK: Lifecycle

    init(setChangeInfo: SetChangeInfo<ZMConversation>) {
        self.setChangeInfo = setChangeInfo
    }

    // MARK: Public

    public typealias ChangeInfoContent = ZMConversation

    public var setChangeInfo: SetChangeInfo<ZMConversation>

    public var conversationList: ConversationList { setChangeInfo.observedObject as! ConversationList }

    public var orderedSetState: OrderedSetState<ChangeInfoContent> { setChangeInfo.orderedSetState }
    public var insertedIndexes: IndexSet { setChangeInfo.insertedIndexes }
    public var deletedIndexes: IndexSet { setChangeInfo.deletedIndexes }
    public var deletedObjects: Set<AnyHashable> { setChangeInfo.deletedObjects }
    public var updatedIndexes: IndexSet { setChangeInfo.updatedIndexes }
    public var movedIndexPairs: [MovedIndex] { setChangeInfo.movedIndexPairs }
    public var zm_movedIndexPairs: [ZMMovedIndex] { setChangeInfo.zm_movedIndexPairs }

    public func enumerateMovedIndexes(_ block: @escaping (_ from: Int, _ to: Int) -> Void) {
        setChangeInfo.enumerateMovedIndexes(block)
    }
}

// MARK: - ZMConversationListObserver

@objc
public protocol ZMConversationListObserver: NSObjectProtocol {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo)
    @objc
    optional func conversationInsideList(_ list: ConversationList, didChange changeInfo: ConversationChangeInfo)
}

// MARK: - ZMConversationListReloadObserver

@objc
public protocol ZMConversationListReloadObserver: NSObjectProtocol {
    func conversationListsDidReload()
}

// MARK: - ZMConversationListFolderObserver

@objc
public protocol ZMConversationListFolderObserver: NSObjectProtocol {
    func conversationListsDidChangeFolders()
}

extension ConversationListChangeInfo {
    /// Adds a ZMConversationListObserver to the specified list
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forList:managedObjectContext:)
    public static func addListObserver(
        _ observer: ZMConversationListObserver,
        for list: ConversationList?,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        if let list {
            zmLog.debug("Registering observer \(observer) for list \(list.identifier)")
        } else {
            zmLog.debug("Registering observer \(observer) for all lists")
        }

        return ManagedObjectObserverToken(
            name: .conversationListDidChange,
            managedObjectContext: managedObjectContext,
            object: list
        ) { [weak observer] note in
            guard let observer, let aList = note.object as? ConversationList else { return }

            zmLog.debug("Notifying registered observer \(observer) about changes in list: \(aList.identifier)")

            if let changeInfo = note.userInfo["conversationListChangeInfo"] as? ConversationListChangeInfo {
                observer.conversationListDidChange(changeInfo)
            }
            if let changeInfos = note.userInfo["conversationChangeInfos"] as? [ConversationChangeInfo] {
                for changeInfo in changeInfos {
                    observer.conversationInsideList?(aList, didChange: changeInfo)
                }
            }
        }
    }

    @objc(addConversationListReloadObserver:managedObjectcontext:)
    public static func addReloadObserver(
        _ observer: ZMConversationListReloadObserver,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .conversationListsDidReload,
            managedObjectContext: managedObjectContext,
            block: { [weak observer] _ in
                observer?.conversationListsDidReload()
            }
        )
    }

    @objc(addConversationListFolderObserver:managedObjectcontext:)
    public static func addFolderObserver(
        _ observer: ZMConversationListFolderObserver,
        managedObjectContext: NSManagedObjectContext
    ) -> NSObjectProtocol {
        ManagedObjectObserverToken(
            name: .conversationListDidChangeFolders,
            managedObjectContext: managedObjectContext,
            block: { [weak observer] _ in
                observer?.conversationListsDidChangeFolders()
            }
        )
    }
}
