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
#if os(iOS)
    import CoreTelephony
#endif
import ZMCSystem

private let zmLog = ZMSLog(tag: "Observer")

public enum ObjectObserverType: Int {
    
    // The order of this enum is important, because some event create additional observer to fire (reaction fires message notification), 
    // and therefore needs to happen before the message observer handler to propagate properly to the UI
    case invalid = 0
    case connection
    case client
    case userList
    case user
    case displayName
    case searchUser
    case message
    case conversation
    case voiceChannel
    case reaction
    case conversationMessageWindow
    case conversationList

    static func observerTypeForObject(_ object: NSObject) -> ObjectObserverType {
        
        if object is ZMConnection {
            return .connection
        } else if object is ZMUser {
            return .user
        } else if object is ZMMessage {
            return .message
        } else if object is ZMConversation {
            return .conversation
        } else if object is ZMSearchUser {
            return .searchUser
        } else if object is ZMCDataModel.Reaction {
            return .reaction
        } else if object is UserClient {
            return .client
        }
        return .invalid
    }
    
    var shouldForwardDuringSync : Bool {
        switch self {
        case .invalid, .client, .userList, .user, .searchUser, .message, .conversation, .voiceChannel, .conversationMessageWindow, .displayName, .reaction:
            return false
        case .conversationList, .connection:
            return true
        }
    }
    
    func observedObjectType() -> ObjectObserverType {
        switch self {
        case .voiceChannel, .conversationMessageWindow, .conversationList:
            return .conversation
        case .userList, .displayName:
            return .user
        default:
            return self
        }
    }
    
    func printDescription() -> String {
        switch self {
        case .invalid:
            return "Invalid"
        case .connection:
            return "Connection"
        case .user:
            return "User"
        case .searchUser:
            return "SearchUser"
        case .message:
            return "Message"
        case .conversation:
            return "Conversation"
        case .voiceChannel:
            return "VoiceChannel"
        case .conversationMessageWindow:
            return "ConversationMessageWindow"
        case .conversationList:
            return "ConversationList"
        case .client:
            return "UserClient"
        case .userList:
            return "UserList"
        case .displayName:
            return "DisplayName"
        case .reaction:
            return "Reaction"
        }
    }
}

public struct ManagedObjectChangesByObserverType {
    fileprivate let inserted: [ObjectObserverType : [NSObject]]
    fileprivate let deleted: [ObjectObserverType : [NSObject]]
    fileprivate let updated: [ObjectObserverType : [NSObject]]
    
    static func mapByObjectObserverType(_ set: [NSObject]) -> [ObjectObserverType : [NSObject]] {
        var mapping : [ObjectObserverType : [NSObject]] = [:]
        for obj in set {
            let observerType = ObjectObserverType.observerTypeForObject(obj)
            let previous = mapping[observerType] ?? []
            mapping[observerType] = previous + [obj]
        }
        return mapping
    }
    
    init(inserted: [NSObject], deleted: [NSObject], updated: [NSObject]){
        self.inserted = ManagedObjectChangesByObserverType.mapByObjectObserverType(inserted)
        self.deleted = ManagedObjectChangesByObserverType.mapByObjectObserverType(deleted)
        self.updated = ManagedObjectChangesByObserverType.mapByObjectObserverType(updated)
    }
    
    init(changes: ManagedObjectChanges) {
        self.init(inserted: changes.inserted, deleted: changes.deleted, updated: changes.updated)
    }
    
    func changesForObserverType(_ observerType : ObjectObserverType) -> ManagedObjectChanges {
        
        let objectType = observerType.observedObjectType()
        
        let filterInserted = inserted[objectType] ?? []
        let filterDeleted = deleted[objectType] ?? []
        let filterUpdated = updated[objectType] ?? []
        
        return ManagedObjectChanges(
            inserted: filterInserted,
            deleted: filterDeleted,
            updated: filterUpdated
        )
    }
}

public struct ManagedObjectChanges: CustomDebugStringConvertible {
    
    public let inserted: [NSObject]
    public let deleted: [NSObject]
    public let updated: [NSObject]
    
    public init(inserted: [NSObject], deleted: [NSObject], updated: [NSObject]){
        self.inserted = inserted
        self.deleted = deleted
        self.updated = updated
    }
    
    init() {
        self.inserted = []
        self.deleted = []
        self.updated = []
    }
    
    func changesByAppendingChanges(_ changes: ManagedObjectChanges) -> ManagedObjectChanges {
        let inserted = self.inserted + changes.inserted
        let deleted = self.deleted + changes.deleted
        let updated = self.updated + changes.updated
        
        return ManagedObjectChanges(inserted: inserted, deleted: deleted, updated: updated)
    }
    
    public var changesWithoutZombies: ManagedObjectChanges {
        let isNoZombie: (NSObject) -> Bool = {
            guard let managedObject = $0 as? ZMManagedObject else { return true }
            return !managedObject.isZombieObject
        }

        return ManagedObjectChanges(
            inserted: inserted.filter(isNoZombie),
            deleted: deleted,
            updated: updated.filter(isNoZombie)
        )
    }
    
    init(note: Notification) {

        var inserted, deleted: [NSObject]?
        var updatedAndRefreshed = [NSObject]()
        
        if let insertedSet = note.userInfo?[NSInsertedObjectsKey] as? Set<NSObject> {
            inserted = Array(insertedSet)
        }
        
        if let deletedSet = note.userInfo?[NSDeletedObjectsKey] as? Set<NSObject> {
            deleted = Array(deletedSet)
        }
        
        if let updatedSet = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSObject> {
            updatedAndRefreshed.append(contentsOf: updatedSet)
        }
        
        if let refreshedSet = note.userInfo?[NSRefreshedObjectsKey] as? Set<NSObject> {
            updatedAndRefreshed.append(contentsOf: refreshedSet)
        }
        
        self.init(inserted: inserted ?? [], deleted: deleted ?? [], updated: updatedAndRefreshed)
    }
    
    public var debugDescription : String { return "Inserted: \(SwiftDebugging.shortDescription(inserted)), updated: \(SwiftDebugging.shortDescription(updated)), deleted: \(SwiftDebugging.shortDescription(deleted))" }
    public var description : String { return debugDescription }
    
    public var isEmpty : Bool {
        return self.inserted.count + self.updated.count + self.deleted.count == 0
    }
}

public func +(lhs: ManagedObjectChanges, rhs: ManagedObjectChanges) -> ManagedObjectChanges {
    return lhs.changesByAppendingChanges(rhs)
}

public protocol ObjectsDidChangeDelegate: NSObjectProtocol {
    func objectsDidChange(_ changes: ManagedObjectChanges)
    func tearDown()
    var isTornDown : Bool { get }
}

public protocol DisplayNameDidChangeDelegate {
    func displayNameMightChange(_ users: Set<NSObject>)
}


// MARK: - ManagedObjectContextObserver

let ManagedObjectContextObserverKey = "ManagedObjectContextObserverKey"

extension NSManagedObjectContext {
    
    public var globalManagedObjectContextObserver : ManagedObjectContextObserver {
        if let observer = self.userInfo[ManagedObjectContextObserverKey] as? ManagedObjectContextObserver {
            return observer
        }
        
        let newObserver = ManagedObjectContextObserver(managedObjectContext: self)
        self.userInfo[ManagedObjectContextObserverKey] = newObserver
        newObserver.setup()
        return newObserver
    }
}

public final class ManagedObjectContextObserver: NSObject {
    
    typealias ObserversCollection = [ObjectObserverType : NSHashTable<AnyObject>]
    
    fileprivate var observers : ObserversCollection = [:]

    public weak var managedObjectContext : NSManagedObjectContext?
    
    fileprivate var globalConversationObserver : GlobalConversationObserver!
    fileprivate var globalUserObserver : GlobalUserObserver!
    
    fileprivate var accumulatedChanges = ManagedObjectChanges()
    fileprivate var changedCallStateConversations = ManagedObjectChanges()
    fileprivate var isSyncDone = false
    
    public let callCenter = CTCallCenter()
    
    
    public var propagateChanges = false {
        didSet {
            if propagateChanges {
                propagateAccumulatedChanges()
            }
        }
    }
    
    public var isReady : Bool {
        if !globalConversationObserver.isReady && propagateChanges {
            addChangeObserver(self.globalUserObserver, type: .userList)
            addChangeObserver(self.globalUserObserver, type: .connection)
            
            addChangeObserver(self.globalConversationObserver, type: .conversationList)
            addChangeObserver(self.globalConversationObserver, type: .connection)
            
            // this last step sets isReady to true
            globalConversationObserver.prepareObservers()
        }
        return globalConversationObserver.isReady
    }
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ManagedObjectContextObserver.managedObjectsDidChange(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(ManagedObjectContextObserver.syncCompleted(_:)), name: NSNotification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
    }
    
    func setup() {
        self.globalUserObserver = GlobalUserObserver(managedObjectContext: managedObjectContext!)
        self.globalConversationObserver = GlobalConversationObserver(managedObjectContext: managedObjectContext!)
    }
    
    public func tearDown() {
        self.globalConversationObserver.tearDown()
        self.globalUserObserver.tearDown()
        for hashTable in self.observers.values {
            for observer in hashTable.allObjects {
                if let observer = observer as? ObjectsDidChangeDelegate {
                    observer.tearDown()
                }
            }
        }
        self.observers = [:]

        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
       tearDown()
    }
    
    public func syncCompleted(_ note: Notification) {
        self.managedObjectContext!.performGroupedBlock {
            if !self.isReady {
                zmLog.error("Sync completed but global conversation observer is not ready to observe")
            }
            self.isSyncDone = true
            self.globalConversationObserver.isSyncComplete = true
            self.globalConversationObserver.checkAllConversationsForChanges()
        }
    }
    
    func changesFromDisplayNameGenerator(_ note: Notification) -> ManagedObjectChanges {
        let updatedUsers = self.managedObjectContext!.updateDisplayNameGenerator(withChanges: note) ?? Set()
        if updatedUsers.count > 0 {
            globalUserObserver.displayNameMightChange(updatedUsers as Set<NSObject>)
        }
        let changes = ManagedObjectChanges(inserted: [], deleted: [], updated: Array(updatedUsers) as [NSObject])
        return changes
    }
    
    func processChanges(_ changes: ManagedObjectChanges) {
        guard isReady else { return }

        if propagateChanges {
            propagateChangesToObservers(changes)
        } else {
            accumulatedChanges = accumulatedChanges + changes
        }
    }
    
    func managedObjectsDidChange(_ note: Notification) {
        guard isReady else { return }

        let changes = ManagedObjectChanges(note: note)
            + changesFromDisplayNameGenerator(note)
            + changedCallStateConversations
        
        changedCallStateConversations = ManagedObjectChanges()
        processChanges(changes)
    }
    
    fileprivate func propagateAccumulatedChanges() {
        self.managedObjectContext!.performGroupedBlock {
            if !self.isReady {
                zmLog.error("Application want to propagate changes but global conversation observer is not ready to observe")
            }
            let changes = self.accumulatedChanges
            self.accumulatedChanges = ManagedObjectChanges()
            self.propagateChangesToObservers(changes)
        }
    }
    
    fileprivate func propagateChangesToObservers(_ changes: ManagedObjectChanges) {
        
        let tp = ZMSTimePoint(interval: 10, label: "ManagedObjectContextObserver propagateChangesToObserver")
        let changesByType = ManagedObjectChangesByObserverType(changes: changes)
        
        var index = 1
        while let observerType = ObjectObserverType(rawValue: index) {
            if !observerType.shouldForwardDuringSync && !isSyncDone {
                index += 1
                continue
            }
            let changesForObservers = changesByType.changesForObserverType(observerType)
            propagateChangesForObservers(changesForObservers, observerType: observerType)
            index += 1
        }
        tp?.warnIfLongerThanInterval()
    }
    
    func count(forEntityWithName entityName: String) -> Int? {
        return try? self.managedObjectContext!.count(for: NSFetchRequest(entityName: entityName))

    }
    
    func printCurrentTokens() {
        var index = 1
        while let observerType = ObjectObserverType(rawValue: index) {
            print(">>> ObserverType: \(observerType) - token count: \(self.observers[observerType]?.count ?? 0)")
            index += 1
        }
        let userCount = count(forEntityWithName: ZMUser.entityName())
        let convCount = count(forEntityWithName: ZMConversation.entityName())
        let clientCount = count(forEntityWithName: UserClient.entityName())
        let connectionCount = count(forEntityWithName: ZMConnection.entityName())
        let messageCount = count(forEntityWithName: ZMMessage.entityName())

        print("Existing Users: \(userCount), Conversations: \(convCount), Clients: \(clientCount), Connections: \(connectionCount), MessageCount: \(messageCount)")
    }
    
    @objc public func notifyUpdatedSearchUser(_ user: NSObject) {
        guard isReady else { return }

        let changes = ManagedObjectChanges(inserted: [], deleted: [], updated: [user])
        propagateChangesForObservers(changes, observerType: .searchUser)
    }
        
    @objc public func notifyUpdatedCallState(_ conversations: Set<ZMConversation>, notifyDirectly: Bool) {
        guard isReady else { return }

        let changes = ManagedObjectChanges(inserted: [], deleted: [], updated: Array(conversations))

        if notifyDirectly {
            processChanges(changes)
        } else {
            changedCallStateConversations = changedCallStateConversations + changes
        }
    }
    
    @objc public func notifyNonCoreDataChangeInManagedObject(_ object: NSObject) {
        let changes = ManagedObjectChanges(inserted: [], deleted: [], updated: [object])
        self.processChanges(changes)
    }
    
    
    func propagateChangesForObservers(_ changes: ManagedObjectChanges, observerType: ObjectObserverType) {
        if let observersOfType = self.observers[observerType] {
            let filteredChanges = changes.changesWithoutZombies
            for observer in observersOfType.allObjects {
                (observer as? ObjectsDidChangeDelegate)?.objectsDidChange(filteredChanges)
            }
        }
    }
}


// MARK: - ConversationList
extension ManagedObjectContextObserver {
    
    public func addConversationListForAutoupdating(_ conversationList: ZMConversationList) {
        self.globalConversationObserver.addConversationList(conversationList)
    }
    
    public func removeConversationListForAutoupdating(_ conversationList: ZMConversationList) {
        self.globalConversationObserver.removeConversationList(conversationList)
    }
    
}



// MARK: - Add/remove observer
extension ManagedObjectContextObserver  {
    
    /// Adds a generic observer for a given object
    public func addChangeObserver(_ observer: ObjectsDidChangeDelegate, object: NSObject) {
        let type = ObjectObserverType.observerTypeForObject(object)
        self.addChangeObserver(observer, type: type)
    }
    
    /// Adds an observer of the given type
    public func addChangeObserver(_ observer: ObjectsDidChangeDelegate, type: ObjectObserverType) {
        assert(type != .invalid)
        let table = self.observers[type] ?? NSHashTable.weakObjects()
        table.add(observer)
        self.observers[type] = table
    }
    
    /// Adds a conversation list observer
    public func addConversationListObserver(_ observer: ZMConversationListObserver, conversationList: ZMConversationList) -> AnyObject
    {
        return self.globalConversationObserver.addObserver(observer, conversationList: conversationList)
    }
    
    /// Adds a global voiceChannel observer
    public func addGlobalVoiceChannelObserver(_ observer: ZMVoiceChannelStateObserver) -> AnyObject
    {
        return self.globalConversationObserver.addGlobalVoiceChannelStateObserver(observer)
    }
    
    /// Adds a voiceChannel observer
    public func addVoiceChannelStateObserver(_ observer: ZMVoiceChannelStateObserver, conversation: ZMConversation) -> AnyObject
    {
        return self.globalConversationObserver.addVoiceChannelStateObserver(observer, conversation: conversation)
    }
    
    /// Adds a conversation list observer
    public func addConversationObserver(_ observer: ZMConversationObserver, conversation: ZMConversation) -> AnyObject
    {
        return self.globalConversationObserver.addConversationObserver(observer, conversation: conversation)
    }
    
    /// Adds a conversation list observer
    public func addUserObserver(_ observer: ZMUserObserver, user: ZMBareUser) -> AnyObject?
    {
        return self.globalUserObserver.addUserObserver(observer, user: user)
    }
    
    /// Adds a voiceChannel participant observer
    public func addCallParticipantsObserver(_ observer: ZMVoiceChannelParticipantsObserver, voiceChannel: ZMVoiceChannel) -> AnyObject
    {
        let token = self.globalConversationObserver.addVoiceChannelParticipantsObserver(observer, conversation: voiceChannel.conversation!)
        return token
    }
    
    /// Adds a conversation window observer
    public func addConversationWindowObserver(_ observer: ZMConversationMessageWindowObserver, window: ZMConversationMessageWindow) -> MessageWindowChangeToken {
        let token = MessageWindowChangeToken(window: window, observer: observer)
        self.addChangeObserver(token, type: ObjectObserverType.conversationMessageWindow)
        return token
    }
    
    /// Adds a new unread messages observer
    public func addNewUnreadMessagesObserver(_ observer: ZMNewUnreadMessagesObserver) -> NewUnreadMessagesObserverToken {
        let token = NewUnreadMessagesObserverToken(observer: observer)
        self.addChangeObserver(token, type: .message)
        return token
    }
    
    /// Adds a new unread knockmessages observer
    public func addNewUnreadKnocksObserver(_ observer: ZMNewUnreadKnocksObserver) -> NewUnreadKnockMessagesObserverToken {
        let token = NewUnreadKnockMessagesObserverToken(observer: observer)
        self.addChangeObserver(token, type: .message)
        return token
    }
    
    /// Adds a new unread unsent observer
    public func addNewUnreadUnsentMessagesObserver(_ observer: ZMNewUnreadUnsentMessageObserver) -> NewUnreadUnsentMessageObserverToken {
        let token = NewUnreadUnsentMessageObserverToken(observer: observer)
        self.addChangeObserver(token, type: .message)
        return token
    }
    
    public func addDisplayNameObserver(_ observer: DisplayNameObserver) {
        self.globalUserObserver.addDisplayNameObserver(observer)
    }
    
    /// Removes a generic observer for a given object
    public func removeChangeObserver(_ observer: ObjectsDidChangeDelegate, object: NSObject){
        let type = ObjectObserverType.observerTypeForObject(object)
        self.removeChangeObserver(observer, type: type)
    }
    
    /// Removes a generic observer for a given type
    public func removeChangeObserver(_ observer: ObjectsDidChangeDelegate, type: ObjectObserverType){
        if let observersOfType : NSHashTable = self.observers[type] {
            observersOfType.remove(observer)
            if !observer.isTornDown {
                observer.tearDown()
            }
        }
    }
    
    /// Removes a conversation list observer
    public func removeConversationListObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? ConversationListObserverToken {
            self.globalConversationObserver.removeObserver(observerToken)
        }
    }
    
    /// Removes a conversation observer
    public func removeConversationObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? ConversationObserverToken {
            self.globalConversationObserver.removeConversationObserverForToken(observerToken)
        }
    }
    
    /// Removes a conversation observer
    public func removeUserObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? UserObserverToken {
            self.globalUserObserver.removeUserObserverForToken(observerToken)
        }
    }
    
    /// Removes a global voiceChannel observer
    public func removeGlobalVoiceChannelStateObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? GlobalVoiceChannelStateObserverToken {
            self.globalConversationObserver.removeGlobalVoiceChannelStateObserver(observerToken)
        }
    }
    
    /// Removes a global voiceChannel observer
    public func removeVoiceChannelStateObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? VoiceChannelStateObserverToken {
            self.globalConversationObserver.removeVoiceChannelStateObserverForToken(observerToken)
        }
    }
    
    /// Removes a voiceChannel participant observer
    public func removeCallParticipantsObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? VoiceChannelParticipantsObserverToken {
            self.globalConversationObserver.removeVoiceChannelParticipantsObserverForToken(observerToken)
        }
    }
    
    /// Removes a message window observer
    public func removeConversationWindowObserverForToken(_ token: AnyObject) {
        if let observerToken = token as? MessageWindowChangeToken {
            self.removeChangeObserver(observerToken, type: ObjectObserverType.conversationMessageWindow)
        }
    }
    
    /// Removes a message observer
    public func removeMessageObserver(_ token: AnyObject) {
        if let token = token as? MessageToken {
            self.removeChangeObserver(token, type: .message)
        }
    }
    
    public func removeDisplayNameObserver(_ observer: DisplayNameObserver) {
        self.globalUserObserver.removeDisplayNameObserver(observer)
    }
}

