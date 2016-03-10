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


import Foundation
import ZMCSystem

final class GlobalConversationObserver : NSObject, ObjectsDidChangeDelegate, ZMGeneralConversationObserver {
    
    private var conversationListObserverTokens : Set<ConversationListObserverToken> = Set()
    private var globalVoiceChannelObserverTokens : Set<GlobalVoiceChannelStateObserverToken> = Set()

    private var conversationTokens : [ZMConversation : GeneralConversationObserverToken<GlobalConversationObserver>] = [:]
    private let managedObjectContext : NSManagedObjectContext
    
    private var conversationLists : [UnownedObject<ZMConversationList>] = Array()
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName:ZMConversation.entityName())
        fetchRequest.includesPendingChanges = false;
        let allConversations = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [ZMConversation] ?? []

        super.init()
        
        self.registerTokensForConversations(Set(allConversations))
    }
    
    // adding and removing lists
    func addConversationList(conversationList: ZMConversationList) {
        if !self.isObservingConversationList(conversationList) {
            self.conversationLists.append(UnownedObject(conversationList))
        }
    }
    
    func removeConversationList(conversationList: ZMConversationList) {
        self.conversationLists = self.conversationLists.filter { $0.unbox != conversationList}
    }
    
    // adding tokens for conversations
    private func registerTokensForConversations(conversations: Set<ZMConversation>) {
        for conv in conversations {
            if self.conversationTokens[conv] == nil {
                self.conversationTokens[conv] = GeneralConversationObserverToken<GlobalConversationObserver>(observer: self, conversation: conv)
            }
        }
    }
    
    private func removeTokensForConversations(conversations: Set<ZMConversation>) {
        for conv in conversations {
            self.conversationTokens.removeValueForKey(conv)
        }
    }
    
    // handling object changes
    func objectsDidChange(changes: ManagedObjectChanges) {
        
        let insertedSet = Set(changes.inserted as! [ZMConversation])
        let deletedSet = Set(changes.deleted as! [ZMConversation])
        
        for listWrapper in conversationLists {
            if let list = listWrapper.unbox {
                updateListAndNotifyObservers(list, inserted: insertedSet , deleted: deletedSet)
            }
        }
        
        registerTokensForConversations(insertedSet)
        removeTokensForConversations(deletedSet)
    }
    
    private func updateListAndNotifyObservers(list: ZMConversationList, inserted: Set<ZMConversation>, deleted: Set<ZMConversation>) {
        let conversationsToInsert = Set(inserted.filter { list.predicateMatchesConversation($0)})
        let conversationsToRemove = Set(deleted.filter { list.containsObject($0)})
        
        list.insertConversations(conversationsToInsert)
        list.removeConversations(conversationsToRemove)
        
        if !conversationsToInsert.isEmpty || !conversationsToRemove.isEmpty {
            self.notifyTokensForConversationList(list, updatedConversation: nil, changes: nil)
        }
    }
    
    func conversationDidChange(allChanges: GeneralConversationChangeInfo) {
        if let voiceChannelInfo = allChanges.voiceChannelStateChangeInfo {
            self.processVoiceChannelStateChanges(voiceChannelInfo)
        }
        if let convInfo = allChanges.conversationChangeInfo {
            self.processConversationChanges(convInfo)
        }
    }
    
    func processVoiceChannelStateChanges(note: VoiceChannelStateChangeInfo) {
        for token in self.globalVoiceChannelObserverTokens {
            token.notifyObserver(note)
        }
    }
    func processConversationChanges(changes: ConversationChangeInfo) {
        if (!changes.nameChanged && !changes.connectionStateChanged && !changes.isArchivedChanged && !changes.isSilencedChanged && !changes.lastModifiedDateChanged && !changes.conversationListIndicatorChanged && !changes.voiceChannelStateChanged && !changes.clearedChanged && !changes.securityLevelChanged) {
            return
        }
        for conversationListWrapper in self.conversationLists
        {
            if let list = conversationListWrapper.unbox {
                let conversation = changes.object as! ZMConversation
                
                if list.containsObject(conversation)
                {
                    var didRemoveConversation = false
                    if !list.predicateMatchesConversation(conversation){
                        list.removeConversations(Set(arrayLiteral: conversation))
                        didRemoveConversation = true
                    }
                    let a = changes.changedKeys.map { $0.rawValue }
                    if !didRemoveConversation && list.sortingIsAffectedByConversationKeys(Set(a)) {
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
    
    private func notifyTokensForConversationList(conversationList: ZMConversationList, updatedConversation: ZMConversation?, changes:ConversationChangeInfo?) {
        for token in conversationListObserverTokens.filter({ $0.conversationList === conversationList}) {
            token.notifyObserver(updatedConversation, changes: changes)
        }
    }
    
    private func isObservingConversationList(conversationList: ZMConversationList) -> Bool {
        return self.conversationLists.filter({$0.unbox === conversationList}).count > 0
    }
    
    func tearDown() {
        for (_, value) in self.conversationTokens {
            value.tearDown()
        }
        conversationTokens = [:]
        conversationListObserverTokens = Set()
        globalVoiceChannelObserverTokens =  Set()
        conversationLists = []
    }
}




extension GlobalConversationObserver {
    
    // adding and removing list observers
    func addObserver(observer: ZMConversationListObserver, conversationList: ZMConversationList) -> ConversationListObserverToken
    {
        let token = ConversationListObserverToken(conversationList:conversationList, observer: observer)
        self.conversationListObserverTokens.insert(token)
        return token
    }
    
    func removeObserver(token: ConversationListObserverToken) {
        self.conversationListObserverTokens.remove(token)
    }
    
    
    // adding and removing voiceChannel observers
    func addGlobalVoiceChannelStateObserver(observer: ZMVoiceChannelStateObserver) -> GlobalVoiceChannelStateObserverToken
    {
        let token = GlobalVoiceChannelStateObserverToken(observer: observer)
        self.globalVoiceChannelObserverTokens.insert(token)
        return token
    }
    
    func removeGlobalVoiceChannelStateObserver(token: GlobalVoiceChannelStateObserverToken) {
        self.globalVoiceChannelObserverTokens.remove(token)
    }
}


