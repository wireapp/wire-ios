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


protocol ChangeNotifierToken : NSObjectProtocol {
    associatedtype Observer
    associatedtype ChangeInfo
    associatedtype GlobalObserver
    
    func tearDown()
    func notifyObserver(note: ChangeInfo)
    init (observer: Observer, globalObserver: GlobalObserver)
}

class TokenCollection<T : NSObject where T : ChangeNotifierToken> {
    var observerTokens : [NSObject : NSHashTable] = [:]
    
    func addObserver(observer: T.Observer, object: NSObject, globalObserver: T.GlobalObserver) -> T {
        let token = T(observer: observer, globalObserver: globalObserver)
        let tokens = observerTokens[object] ?? NSHashTable.weakObjectsHashTable()
        tokens.addObject(token)
        observerTokens[object] = tokens
        return token
    }
    
    func objectCanBeUnobservedAfterRemovingObserverForToken(token: T) -> NSObject? {
        for (object, tokens) in observerTokens {
            if tokens.containsObject(token) {
                tokens.removeObject(token)
                observerTokens[object] = tokens
                return (tokens.count == 0) ? object : nil
            }
        }
        return nil
    }
    
    func removeTokensForObject(key: NSObject) {
        observerTokens.removeValueForKey(key)
    }
    
    subscript (key: NSObject) -> [T]? {
        return observerTokens[key]?.allObjects as? [T]
    }
}

final class GlobalConversationObserver : NSObject, ObjectsDidChangeDelegate, ZMGeneralConversationObserver, ZMConversationListObserver {
    
    private var internalConversationListObserverTokens : [String :InternalConversationListObserverToken] = [:]
    private var globalVoiceChannelObserverTokens : Set<GlobalVoiceChannelStateObserverToken> = Set()

    private var conversationTokens : [NSManagedObjectID : GeneralConversationObserverToken<GlobalConversationObserver>] = [:]
    private var voiceChannelParticipantsTokens : [NSManagedObjectID : InternalVoiceChannelParticipantsObserverToken] = [:]

    private let managedObjectContext : NSManagedObjectContext
    
    private var conversationLists : [UnownedObject<ZMConversationList>] = Array()
    
    private var conversationListObserverTokens : TokenCollection<ConversationListObserverToken> =  TokenCollection()
    private var conversationObserverTokens : TokenCollection<ConversationObserverToken> = TokenCollection()
    private var voiceChannelStateObserverTokens : TokenCollection<VoiceChannelStateObserverToken> = TokenCollection()
    private var voiceChannelParticipantsObserverTokens : TokenCollection<VoiceChannelParticipantsObserverToken> = TokenCollection()
    var isSyncComplete: Bool = false
    var isTornDown : Bool = false
    private (set) var isReady : Bool  = false
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    func prepareObservers() {
        isReady = true

        let fetchRequest = NSFetchRequest(entityName:ZMConversation.entityName())
        fetchRequest.includesPendingChanges = false;
        let allConversations = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [ZMConversation] ?? []
        registerTokensForConversations(allConversations)
        
        let observedLists = conversationListObserverTokens.observerTokens.keys
        let lists = conversationLists.flatMap{$0.unbox}.filter{observedLists.contains($0.identifier)}
        registerTokensForConversationList(lists)
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
    
    private func registerTokensForConversationList(lists : [ZMConversationList]) {
        guard isReady  else { return }
        for conversationList in lists {
            if internalConversationListObserverTokens[conversationList.identifier] == nil {
                internalConversationListObserverTokens[conversationList.identifier] = InternalConversationListObserverToken(conversationList: conversationList, observer:self)
            }
        }
    }
    
    // adding tokens for conversations
    private func registerTokensForConversations(conversations: [ZMConversation]) {
        guard isReady else { return }
        for conv in conversations {
            if conv.objectID.temporaryID {
                _ = try? conv.managedObjectContext?.obtainPermanentIDsForObjects([conv])
            }
            if self.conversationTokens[conv.objectID] == nil {
                self.conversationTokens[conv.objectID] = GeneralConversationObserverToken<GlobalConversationObserver>(observer: self, conversation: conv)
            }
        }
    }
    
    private func removeTokensForConversations(conversations: [ZMConversation]) {
        for conv in conversations {
            self.conversationTokens[conv.objectID]?.tearDown()
            self.conversationTokens.removeValueForKey(conv.objectID)
            
            self.voiceChannelParticipantsTokens[conv.objectID]?.tearDown()
            self.voiceChannelParticipantsTokens.removeValueForKey(conv.objectID)
            
            self.conversationObserverTokens.removeTokensForObject(conv.objectID)
            self.voiceChannelStateObserverTokens.removeTokensForObject(conv.objectID)
            self.voiceChannelParticipantsObserverTokens.removeTokensForObject(conv.objectID)
        }
    }
    
    // handling object changes
    func objectsDidChange(changes: ManagedObjectChanges) {
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
                self.updateListAndNotifyObservers(list, inserted: inserted, deleted: deleted)
            }
        }
        self.registerTokensForConversations(inserted)
        self.removeTokensForConversations(deleted)
    }
    
    func checkAllConversationsForChanges(){
        let conversations = conversationObserverTokens.observerTokens.flatMap{try? self.managedObjectContext.existingObjectWithID($0.0 as! NSManagedObjectID)}
        conversations.forEach{
            let changeInfo = GeneralConversationChangeInfo(object: $0)
            changeInfo.setAllKeys()
            conversationDidChange(changeInfo)
            processConversationChanges(changeInfo.conversationChangeInfo!)
        }
    }
    
    private func updateListAndNotifyObservers(list: ZMConversationList, inserted: [ZMConversation], deleted: [ZMConversation]){
        let conversationsToInsert = Set(inserted.filter { list.predicateMatchesConversation($0)})
        let conversationsToRemove = Set(deleted.filter { list.containsObject($0)})
        
        list.insertConversations(conversationsToInsert)
        list.removeConversations(conversationsToRemove)
        
        if (!conversationsToInsert.isEmpty || !conversationsToRemove.isEmpty) && isSyncComplete {
            self.notifyTokensForConversationList(list, updatedConversation: nil, changes: nil)
        }
    }
    
    func conversationDidChange(allChanges: GeneralConversationChangeInfo) {
        if let voiceChannelInfo = allChanges.voiceChannelStateChangeInfo {
            globalVoiceChannelObserverTokens.forEach{ $0.notifyObserver(voiceChannelInfo)}
            voiceChannelStateObserverTokens[allChanges.conversation.objectID]?.forEach{ $0.notifyObserver(voiceChannelInfo) }
        }
        if let convInfo = allChanges.conversationChangeInfo {
            processConversationChanges(convInfo)
            conversationObserverTokens[allChanges.conversation.objectID]?.forEach{ $0.notifyObserver(convInfo) }
        }
        
        voiceChannelParticipantsTokens[allChanges.conversation.objectID]?.conversationDidChange(allChanges)
    }
    
    func conversationInsideList(list: ZMConversationList!, didChange changeInfo: ConversationChangeInfo!) {
        conversationListObserverTokens[list.identifier]?.forEach{$0.conversationInsideList(list, didChange: changeInfo)}
    }
    
    func conversationListDidChange(changeInfo: ConversationListChangeInfo!) {
        conversationListObserverTokens[changeInfo.conversationList.identifier]?.forEach{$0.notifyObserver(changeInfo)}
    }
    
    func notifyVoiceChannelParticipantsObserver(info: VoiceChannelParticipantsChangeInfo!) {
        voiceChannelParticipantsObserverTokens[info.conversation.objectID]?.forEach{
            $0.notifyObserver(info)
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
                    let a = changes.changedKeysAndOldValues.keys
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
        internalConversationListObserverTokens[conversationList.identifier]?.notifyObserver(updatedConversation, changes: changes)
    }
    
    private func isObservingConversationList(conversationList: ZMConversationList) -> Bool {
        return self.conversationLists.filter({$0.unbox === conversationList}).count > 0
    }
    
    func tearDown() {
        if isTornDown { return }
        isTornDown = true
        
        conversationTokens.values.forEach{$0.tearDown()}
        conversationTokens = [:]

        voiceChannelParticipantsTokens.values.forEach{$0.tearDown()}
        voiceChannelParticipantsTokens = [:]
        
        internalConversationListObserverTokens.values.forEach{$0.tearDown()}
        internalConversationListObserverTokens = [:]
        
        globalVoiceChannelObserverTokens.forEach{$0.tearDown()}
        globalVoiceChannelObserverTokens =  Set()
        
        conversationObserverTokens = TokenCollection()
        conversationListObserverTokens = TokenCollection()
        voiceChannelStateObserverTokens = TokenCollection()
        voiceChannelParticipantsObserverTokens = TokenCollection()
    
        conversationLists = []
    }
}




extension GlobalConversationObserver {
    
    // adding and removing list observers
    func addObserver(observer: ZMConversationListObserver, conversationList: ZMConversationList) -> ConversationListObserverToken
    {
        registerTokensForConversationList([conversationList])
        let token = conversationListObserverTokens.addObserver(observer, object: conversationList.identifier, globalObserver: self)
        return token
    }
    
    func removeObserver(token: ConversationListObserverToken) {
        if let conversationListID = conversationListObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token) as? String {
            let token = internalConversationListObserverTokens[conversationListID]
            token?.tearDown()
            internalConversationListObserverTokens.removeValueForKey(conversationListID)
        }
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
    
    
    func addConversationObserver(observer: ZMConversationObserver, conversation: ZMConversation) -> ConversationObserverToken {
        registerTokensForConversations([conversation])
        return conversationObserverTokens.addObserver(observer, object: conversation.objectID, globalObserver: self)
    }
    
    func removeConversationObserverForToken(token: ConversationObserverToken) {
        conversationObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token)
    }
    
    func addVoiceChannelStateObserver(observer: ZMVoiceChannelStateObserver, conversation: ZMConversation) -> VoiceChannelStateObserverToken {
        registerTokensForConversations([conversation])
        return voiceChannelStateObserverTokens.addObserver(observer, object: conversation.objectID, globalObserver: self)
    }
    
    func removeVoiceChannelStateObserverForToken(token: VoiceChannelStateObserverToken) {
       voiceChannelStateObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token)
    }
    
    func addVoiceChannelParticipantsObserver(observer: ZMVoiceChannelParticipantsObserver, conversation: ZMConversation) -> VoiceChannelParticipantsObserverToken {
        registerTokensForConversations([conversation])
        if voiceChannelParticipantsTokens[conversation.objectID] == nil {
            let internalToken = InternalVoiceChannelParticipantsObserverToken(observer: self, conversation: conversation)
            voiceChannelParticipantsTokens[conversation.objectID] = internalToken
            managedObjectContext.globalManagedObjectContextObserver.addChangeObserver(internalToken, type: .VoiceChannel)
        }
        return voiceChannelParticipantsObserverTokens.addObserver(observer, object: conversation.objectID, globalObserver: self)
    }
    
    func removeVoiceChannelParticipantsObserverForToken(token: VoiceChannelParticipantsObserverToken) {
        guard let conversation = voiceChannelParticipantsObserverTokens.objectCanBeUnobservedAfterRemovingObserverForToken(token) as? ZMConversation,
            let participantToken = voiceChannelParticipantsTokens[conversation.objectID]
        else { return }
        
        // when all observers unregistered from this conversation, we can unregister for changes as well
        managedObjectContext.globalManagedObjectContextObserver.removeChangeObserver(participantToken, type: .VoiceChannel)
        participantToken.tearDown()
        voiceChannelParticipantsTokens.removeValueForKey(conversation.objectID)
    }
}


