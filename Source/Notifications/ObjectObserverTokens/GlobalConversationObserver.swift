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
import CoreData

protocol ChangeNotifierToken : NSObjectProtocol {
    associatedtype Observer
    associatedtype ChangeInfo
    associatedtype GlobalObserver
    
    func tearDown()
    func notifyObserver(_ note: ChangeInfo)
    init (observer: Observer, globalObserver: GlobalObserver)
}

class TokenCollection<T : NSObject> where T : ChangeNotifierToken {
    var observerTokens : [AnyHashable : NSHashTable<AnyObject>] = [:]
    
    func addObserver(_ observer: T.Observer, object: AnyHashable, globalObserver: T.GlobalObserver) -> T {
        let token = T(observer: observer, globalObserver: globalObserver)
        let tokens = observerTokens[object] ?? NSHashTable.weakObjects()
        tokens.add(token)
        observerTokens[object] = tokens
        return token
    }
    
    func objectCanBeUnobservedAfterRemovingObserverForToken(_ token: T) -> AnyHashable? {
        for (object, tokens) in observerTokens {
            if tokens.contains(token) {
                tokens.remove(token)
                observerTokens[object] = tokens
                return (tokens.count == 0) ? object : nil
            }
        }
        return nil
    }
    
    func removeTokensForObject(_ key: NSObject) {
        observerTokens.removeValue(forKey: key)
    }
    
    subscript (key: AnyHashable) -> [T]? {
        return observerTokens[key]?.allObjects as? [T]
    }
}

final class GlobalConversationObserver : NSObject, ObjectsDidChangeDelegate, ZMGeneralConversationObserver, ZMConversationListObserver {
    
    fileprivate var internalConversationListObserverTokens : [String :InternalConversationListObserverToken] = [:]

    fileprivate var conversationTokens : [NSManagedObjectID : GeneralConversationObserverToken<GlobalConversationObserver>] = [:]

    fileprivate weak var managedObjectContext : NSManagedObjectContext?
    
    fileprivate var conversationLists : [UnownedObject<ZMConversationList>] = Array()
    
    fileprivate var conversationListObserverTokens : TokenCollection<ConversationListObserverToken> =  TokenCollection()
    fileprivate var conversationObserverTokens : TokenCollection<ConversationObserverToken> = TokenCollection()
    
    var isSyncComplete: Bool = false
    var isTornDown : Bool = false
    fileprivate (set) var isReady : Bool  = false
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    func prepareObservers() {
        isReady = true

        let fetchRequest = NSFetchRequest<ZMConversation>(entityName:ZMConversation.entityName())
        fetchRequest.includesPendingChanges = false;
        if let context = managedObjectContext , let allConversations = (try? context.fetch(fetchRequest)) {
            registerTokensForConversations(allConversations)
        }
        
        let observedListsIdentifiers = conversationListObserverTokens.observerTokens.keys
        let lists = conversationLists.flatMap{$0.unbox}.filter{observedListsIdentifiers.contains($0.identifier)}
        registerTokensForConversationList(lists)
    }
    
    // adding and removing lists
    func addConversationList(_ conversationList: ZMConversationList) {
        if !self.isObservingConversationList(conversationList) {
            self.conversationLists.append(UnownedObject(conversationList))
        }
    }
    
    func removeConversationList(_ conversationList: ZMConversationList) {
        self.conversationLists = self.conversationLists.filter { $0.unbox != conversationList}
    }
    
    fileprivate func registerTokensForConversationList(_ lists : [ZMConversationList]) {
        guard isReady  else { return }
        for conversationList in lists {
            if internalConversationListObserverTokens[conversationList.identifier] == nil {
                internalConversationListObserverTokens[conversationList.identifier] = InternalConversationListObserverToken(conversationList: conversationList, observer:self)
            }
        }
    }
    
    // adding tokens for conversations
    fileprivate func registerTokensForConversations(_ conversations: [ZMConversation]) {
        guard isReady else { return }
        for conv in conversations {
            if conv.objectID.isTemporaryID {
                _ = try? conv.managedObjectContext?.obtainPermanentIDs(for: [conv])
            }
            if self.conversationTokens[conv.objectID] == nil {
                self.conversationTokens[conv.objectID] = GeneralConversationObserverToken<GlobalConversationObserver>(observer: self, conversation: conv)
            }
        }
    }
    
    fileprivate func removeTokensForConversations(_ conversations: [ZMConversation]) {
        for conv in conversations {
            self.conversationTokens[conv.objectID]?.tearDown()
            self.conversationTokens.removeValue(forKey: conv.objectID)
            self.conversationObserverTokens.removeTokensForObject(conv.objectID)
        }
    }
    
    // handling object changes
    func objectsDidChange(_ changes: ManagedObjectChanges, accumulated: Bool) {
        let updatedConnections = changes.updated as? [ZMConnection] ?? []
        let insertedConnection  = changes.inserted as? [ZMConnection] ?? []
        
        if updatedConnections.count > 0 || insertedConnection.count > 0 {
            let connections = (insertedConnection + updatedConnections)
            let conversations = connections.flatMap{$0.conversation}
            conversationTokens.values.forEach{$0.connectionDidChange(conversations)}
            return
        }
        
        let deleted = changes.deleted as? [ZMConversation] ?? []
        let inserted = changes.inserted as? [ZMConversation] ?? []
        if deleted.count == 0 && inserted.count == 0 { return }
        
        for listWrapper in self.conversationLists {
            if let list = listWrapper.unbox {
                if accumulated {
                    self.recomputeListAndNotifyObserver(list)
                } else {
                    self.updateListAndNotifyObservers(list, inserted: inserted, deleted: deleted)
                }
            }
        }
        self.registerTokensForConversations(inserted)
        self.removeTokensForConversations(deleted)
    }
    
    func checkAllConversationsForChanges(){
        let conversations = conversationObserverTokens.observerTokens.flatMap{try? self.managedObjectContext?.existingObject(with: $0.0 as! NSManagedObjectID)}
        conversations.flatMap{$0}.forEach {
            let changeInfo = GeneralConversationChangeInfo(object: $0)
            changeInfo.setAllKeys()
            conversationDidChange(changeInfo)
            processConversationChanges(changeInfo.conversationChangeInfo!)
        }
    }
    
    fileprivate func updateListAndNotifyObservers(_ list: ZMConversationList, inserted: [ZMConversation], deleted: [ZMConversation]){
        let conversationsToInsert = Set(inserted.filter { list.predicateMatchesConversation($0)})
        let conversationsToRemove = Set(deleted.filter { list.contains($0)})
        
        list.insertConversations(conversationsToInsert)
        list.removeConversations(conversationsToRemove)
        
        if (!conversationsToInsert.isEmpty || !conversationsToRemove.isEmpty) && isSyncComplete {
            self.notifyTokensForConversationList(list, updatedConversation: nil, changes: nil)
        }
    }
    
    fileprivate func recomputeListAndNotifyObserver(_ list: ZMConversationList) {
        list.resort()
        if (isSyncComplete) {
            self.notifyTokensForConversationList(list, updatedConversation: nil, changes: nil)
        }
    }
    
    func conversationDidChange(_ allChanges: GeneralConversationChangeInfo) {
        
        if let convInfo = allChanges.conversationChangeInfo {
            processConversationChanges(convInfo)
            conversationObserverTokens[allChanges.conversation.objectID]?.forEach{ $0.notifyObserver(convInfo) }
        }
    }
    
    func conversation(inside list: ZMConversationList!, didChange changeInfo: ConversationChangeInfo!) {
        conversationListObserverTokens[list.identifier]?.forEach{$0.conversationInsideList(list, didChange: changeInfo)}
    }
    
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo!) {
        conversationListObserverTokens[changeInfo.conversationList.identifier]?.forEach{$0.notifyObserver(changeInfo)}
    }
    
    func processConversationChanges(_ changes: ConversationChangeInfo) {
        if (!changes.nameChanged && !changes.connectionStateChanged && !changes.isArchivedChanged && !changes.isSilencedChanged && !changes.lastModifiedDateChanged && !changes.conversationListIndicatorChanged && !changes.clearedChanged && !changes.securityLevelChanged) {
            return
        }
        for conversationListWrapper in self.conversationLists
        {
            if let list = conversationListWrapper.unbox {
                let conversation = changes.object as! ZMConversation
                
                if list.contains(conversation)
                {
                    var didRemoveConversation = false
                    if !list.predicateMatchesConversation(conversation) {
                        list.removeConversations(Set(arrayLiteral: conversation))
                        didRemoveConversation = true
                    }
                    let a = changes.changedKeysAndOldValues.keys
                    if !didRemoveConversation && list.sortingIsAffected(byConversationKeys: Set(a)) {
                        list.resortConversation(conversation)
                    }
                    self.notifyTokensForConversationList(list, updatedConversation:conversation, changes: didRemoveConversation ? nil : changes)
                }
                else if list.predicateMatchesConversation(conversation) // list did not contain conversation and now it should
                {
                    list.insertConversations(Set(arrayLiteral: conversation))
                    self.notifyTokensForConversationList(list, updatedConversation:nil, changes:nil)
                }
            }
        }
    }
    
    fileprivate func notifyTokensForConversationList(_ conversationList: ZMConversationList, updatedConversation: ZMConversation?, changes:ConversationChangeInfo?) {
        internalConversationListObserverTokens[conversationList.identifier]?.notifyObserver(updatedConversation, changes: changes)
    }
    
    fileprivate func isObservingConversationList(_ conversationList: ZMConversationList) -> Bool {
        return self.conversationLists.filter({$0.unbox === conversationList}).count > 0
    }
    
    func tearDown() {
        if isTornDown { return }
        isTornDown = true
        
        conversationTokens.values.forEach{$0.tearDown()}
        conversationTokens = [:]
        
        internalConversationListObserverTokens.values.forEach{$0.tearDown()}
        internalConversationListObserverTokens = [:]
        
        conversationObserverTokens = TokenCollection()
        conversationListObserverTokens = TokenCollection()
    
        conversationLists = []
    }
}




extension GlobalConversationObserver {
    
    // adding and removing list observers
    func addObserver(_ observer: ZMConversationListObserver, conversationList: ZMConversationList) -> ConversationListObserverToken
    {
        registerTokensForConversationList([conversationList])
        let token = conversationListObserverTokens.addObserver(observer, object: conversationList.identifier, globalObserver: self)
        return token
    }
    
    func removeObserver(_ token: ConversationListObserverToken) {
        if let conversationListID = conversationListObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token) as? String {
            let token = internalConversationListObserverTokens[conversationListID]
            token?.tearDown()
            internalConversationListObserverTokens.removeValue(forKey: conversationListID)
        }
    }
    
    func addConversationObserver(_ observer: ZMConversationObserver, conversation: ZMConversation) -> ConversationObserverToken {
        registerTokensForConversations([conversation])
        return conversationObserverTokens.addObserver(observer, object: conversation.objectID, globalObserver: self)
    }
    
    func removeConversationObserverForToken(_ token: ConversationObserverToken) {
        _ = conversationObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token)
    }
    
}


