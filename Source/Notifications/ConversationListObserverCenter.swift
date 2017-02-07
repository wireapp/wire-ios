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

private var zmLog = ZMSLog(tag: "ConversationListObserverCenter")

extension Notification.Name {
    static let StartObservingList = Notification.Name("StartObservingListNotification")
    static let ZMConversationListDidChange = Notification.Name("ZMConversationListDidChangeNotification")
}



extension NSManagedObjectContext {
    
    static let ConversationListObserverCenterKey = "ConversationListObserverCenterKey"
    
    public var conversationListObserverCenter : ConversationListObserverCenter {
        assert(zm_isUserInterfaceContext, "ConversationListObserver does not exist in syncMOC")
        
        if let observer = self.userInfo[NSManagedObjectContext.ConversationListObserverCenterKey] as? ConversationListObserverCenter {
            return observer
        }
        
        let newObserver = ConversationListObserverCenter()
        self.userInfo[NSManagedObjectContext.ConversationListObserverCenterKey] = newObserver
        return newObserver
    }
}

public class ConversationListObserverCenter : NSObject, ZMConversationObserver, ChangeInfoConsumer {
    
    fileprivate var listSnapshots : [String : ConversationListSnapshot] = [:]
    
    var isTornDown : Bool = false
    
    /// Adds a conversationList to the objects to observe
    @objc public func startObservingList(_ conversationList: ZMConversationList) {
        if listSnapshots[conversationList.identifier] == nil {
            listSnapshots[conversationList.identifier] = ConversationListSnapshot(conversationList: conversationList)
        }
    }
    
    /// Overwrites the current snapshot of the specified conversationList
    @objc public func recreateSnapshot(for conversationList: ZMConversationList) {
        listSnapshots[conversationList.identifier] = ConversationListSnapshot(conversationList: conversationList)
    }
    
    /// Removes the conversationList from the objects to observe
    @objc public func removeConversationList(_ conversationList: ZMConversationList){
        listSnapshots.removeValue(forKey: conversationList.identifier)
    }
    
    // MARK: Forwarding updates
    public func objectsDidChange(changes: [ClassIdentifier : [ObjectChangeInfo]]) {
        guard let convChanges = changes[ZMConversation.classIdentifier] as? [ConversationChangeInfo] else { return }
        convChanges.forEach{conversationDidChange($0)}
        forwardToSnapshots{$0.recalculateListAndNotify()}
    }
    
    /// Handles updated conversations, updates lists and notifies observers
    public func conversationDidChange(_ changes: ConversationChangeInfo) {
        guard    changes.nameChanged              || changes.connectionStateChanged  || changes.isArchivedChanged
              || changes.isSilencedChanged        || changes.lastModifiedDateChanged || changes.conversationListIndicatorChanged
              || changes.clearedChanged           || changes.securityLevelChanged
        else { return }
        
        forwardToSnapshots{$0.processConversationChanges(changes)}
    }
    
    /// Processes conversationChanges and removes or insert conversations and notifies observers
    func conversationsChanges(inserted: [ZMConversation], deleted: [ZMConversation], accumulated : Bool) {
        if deleted.count == 0 && inserted.count == 0 { return }
        forwardToSnapshots{$0.conversationsChanges(inserted: inserted, deleted: deleted, accumulated: accumulated)}
    }
    
    /// Applys a function on a token and cleares tokens with deallocated lists
    private func forwardToSnapshots(block: ((ConversationListSnapshot) -> Void)) {
        var snapshotsToRemove = [String]()
        listSnapshots.forEach{ (identifier, snapshot) in
            guard snapshot.conversationList != nil else {
                snapshot.tearDown()
                snapshotsToRemove.append(identifier)
                return
            }
            block(snapshot)
        }
        
        // clean up snapshotlist
        snapshotsToRemove.forEach{listSnapshots.removeValue(forKey: $0)}
    }

    func tearDown() {
        if isTornDown { return }
        isTornDown = true
        
        listSnapshots.values.forEach{$0.tearDown()}
        listSnapshots = [:]
    }
    
    public func applicationDidEnterBackground() {
        // We should always recreate the snapshots when reenerting the foreground
        // Therefore it would be safe to clear the snapshots here
        listSnapshots = [:]
    }
    
    public func applicationWillEnterForeground() {
        // list snapshots are automaically recreated when the lists are recreated and `recreateSnapshot(for conversation:)` is called
    }
}


class ConversationListSnapshot: NSObject {
    
    fileprivate var state : SetSnapshot
    weak var conversationList : ZMConversationList?
    fileprivate var tornDown = false
    var conversationChanges = [ConversationChangeInfo]()
    var needsToRecalculate = false
    
    init(conversationList: ZMConversationList) {
        self.conversationList = conversationList
        self.state = SetSnapshot(set: conversationList.toOrderedSet(), moveType: .uiCollectionView)
        super.init()
    }
    
    /// Processes conversationChanges and removes or insert conversations and notifies observers
    fileprivate func processConversationChanges(_ changes: ConversationChangeInfo) {
        guard let list = conversationList else { return }
        
        let conversation = changes.conversation
        if list.contains(conversation) {
            // list contains conversation and needs to be updated
            if !updateDidRemoveConversation(list: list, changes: changes) {
                conversationChanges.append(changes)
            }
            needsToRecalculate = true
        }
        else if list.predicateMatchesConversation(conversation) {
            // list did not contain conversation and now it should
            list.insertConversations(Set(arrayLiteral: conversation))
            needsToRecalculate = true
        }
    }
    
    private func updateDidRemoveConversation(list: ZMConversationList, changes: ConversationChangeInfo) -> Bool {
        if !list.predicateMatchesConversation(changes.conversation) {
            list.removeConversations(Set(arrayLiteral: changes.conversation))
            return true
        }
        if list.sortingIsAffected(byConversationKeys: changes.changedKeys) {
            list.resortConversation(changes.conversation)
        }
        return false
    }
    
    /// Handles inserted and removed conversations, updates lists and notifies observers
    func conversationsChanges(inserted: [ZMConversation], deleted: [ZMConversation], accumulated : Bool) {
        guard let list = conversationList else { return }
        
        if accumulated {
            list.resort()
            needsToRecalculate = true
        } else {
            let conversationsToInsert = Set(inserted.filter { list.predicateMatchesConversation($0)})
            let conversationsToRemove = Set(deleted.filter { list.contains($0)})
            
            list.insertConversations(conversationsToInsert)
            list.removeConversations(conversationsToRemove)
            
            if (!conversationsToInsert.isEmpty || !conversationsToRemove.isEmpty) {
                needsToRecalculate = true
            }
        }
    }
    
    func recalculateListAndNotify() {
        guard let list = self.conversationList, needsToRecalculate || conversationChanges.count > 0 else {
            return
        }
        
        var listChange : ConversationListChangeInfo? = nil
        defer {
            notifyObservers(conversationChanges: conversationChanges, listChanges: listChange)
            conversationChanges = []
            needsToRecalculate = false
        }
        
        let changedSet = NSOrderedSet(array: conversationChanges.flatMap{$0.conversation})
        guard let newStateUpdate = self.state.updatedState(changedSet, observedObject: list, newSet: list.toOrderedSet())
        else { return }
        
        self.state = newStateUpdate.newSnapshot
        listChange = ConversationListChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
    }
    
    private func notifyObservers(conversationChanges: [ConversationChangeInfo], listChanges: ConversationListChangeInfo?) {
        guard listChanges != nil || conversationChanges.count != 0 else { return }
        
        var userInfo = [String : Any]()
        if conversationChanges.count > 0 {
            userInfo["conversationChangeInfos"] = conversationChanges
        }
        if let changes = listChanges {
            userInfo["conversationListChangeInfo"] = changes
        }
        NotificationCenter.default.post(name: .ZMConversationListDidChange, object: self.conversationList, userInfo: userInfo)
    }
    
    func tearDown() {
        state = SetSnapshot(set: NSOrderedSet(), moveType: .none)
        conversationList = nil
        tornDown = true
    }
}
