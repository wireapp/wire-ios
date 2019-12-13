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
import CoreData

private var zmLog = ZMSLog(tag: "notifications")

protocol OpaqueConversationToken : NSObjectProtocol {}

let ChangedKeysAndNewValuesKey = "ZMChangedKeysAndNewValues"

extension Notification.Name {
    
    static let ConversationChange = Notification.Name("ZMConversationChangedNotification")
    static let MessageChange = Notification.Name("ZMMessageChangedNotification")
    static let UserChange = Notification.Name("ZMUserChangedNotification")
    static let SearchUserChange = Notification.Name("ZMSearchUserChangedNotification")
    static let ConnectionChange = Notification.Name("ZMConnectionChangeNotification")
    static let UserClientChange = Notification.Name("ZMUserClientChangeNotification")
    static let NewUnreadMessage = Notification.Name("ZMNewUnreadMessageNotification")
    static let NewUnreadKnock = Notification.Name("ZMNewUnreadKnockNotification")
    static let NewUnreadUnsentMessage = Notification.Name("ZMNewUnreadUnsentMessageNotification")
    static let VoiceChannelStateChange = Notification.Name("ZMVoiceChannelStateChangeNotification")
    static let VoiceChannelParticipantStateChange = Notification.Name("ZMVoiceChannelParticipantStateChangeNotification")
    static let TeamChange = Notification.Name("TeamChangeNotification")
    static let LabelChange = Notification.Name("LabelChangeNotification")
    static let ParticipantRoleChange = Notification.Name("ParticipantRoleChange")

    public static let NonCoreDataChangeInManagedObject = Notification.Name("NonCoreDataChangeInManagedObject")
    
}


/// Creates an object that registers an observer in NSNotificationCenter
/// When this object is deallocated, it automatically unregisters from NSNotificationCenter
/// To receive notifications, make sure to hold a strong reference to this object
/// Note: We keep strong reference to the `object` because the notifications would not get delivered
/// if no one has references to it anymore. This could happen with faulted NSManagedObject.
public class ManagedObjectObserverToken : NSObject {
    
    let token : Any
    private let object: AnyObject?  // We keep strong reference to the `object` because the notifications would not get delivered
                                    // if no one has references to it anymore. This could happen with faulted NSManagedObject.
    
    public init(name: NSNotification.Name,
                managedObjectContext: NSManagedObjectContext,
                object: AnyObject? = nil,
                queue: OperationQueue? = nil,
                block: @escaping (NotificationInContext) -> Void)
    {
        self.object = object
        self.token =  NotificationInContext.addObserver(name: name,
                                                       context: managedObjectContext.notificationContext,
                                                       object: object,
                                                       queue: queue,
                                                       using: block)
    }
}

struct Changes : Mergeable {
    let changedKeys : Set<String>
    let originalChanges : [String : NSObject?]
    
    init(changedKeys: Set<String>) {
        self.changedKeys = changedKeys
        self.originalChanges = [:]
    }
    
    init(changedKeys: Set<String>, originalChanges : [String : NSObject?]) {
        self.changedKeys = changedKeys
        self.originalChanges = originalChanges
    }
    
    func merged(with other: Changes) -> Changes {
        if other.changedKeys.count == 0 && other.originalChanges.count == 0 {
            return self
        }
        return Changes(changedKeys: changedKeys.union(other.changedKeys), originalChanges: originalChanges.updated(other: other.originalChanges))
    }
    
    var hasChangeInfo: Bool {
        return !changedKeys.isEmpty ||
               !originalChanges.isEmpty
    }
}


public typealias ClassIdentifier = String
typealias ObjectAndChanges = [ZMManagedObject : Changes]

@objc public protocol ChangeInfoConsumer : NSObjectProtocol {
    func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]])
    func startObserving()
    func stopObserving()
}

extension ZMManagedObject {
    
    static var classIdentifier : String {
        return entityName()
    }
    
    var classIdentifier: String {
        return type(of: self).entityName()
    }
}

/**
 * Observes changes to observeable entities (messages, users, conversations, ...) by listening to managed object context
 * save notifications or by us manually telling it about non-core data changes. The `NotificationDispatcher` only observes
 * objects on the main (UI) mananged object context.
 */
@objcMembers public class NotificationDispatcher : NSObject {

    fileprivate unowned var managedObjectContext: NSManagedObjectContext
    
    fileprivate var tornDown = false
    private let affectingKeysStore : DependencyKeyStore

    fileprivate var conversationListObserverCenter : ConversationListObserverCenter {
        return managedObjectContext.conversationListObserverCenter
    }
    private var searchUserObserverCenter: SearchUserObserverCenter {
        return managedObjectContext.searchUserObserverCenter
    }
    private let snapshotCenter: SnapshotCenter
    private var changeInfoConsumers = [UnownedNSObject]()
    private var allChangeInfoConsumers : [ChangeInfoConsumer] {
        var consumers = changeInfoConsumers.compactMap{$0.unbox as? ChangeInfoConsumer}
        consumers.append(searchUserObserverCenter)
        consumers.append(conversationListObserverCenter)
        return consumers
    }
    
    /// NotificationCenter tokens
    fileprivate var notificationTokens: [Any] = []
    
    private var allChanges : [ZMManagedObject : Changes] = [:]
    private var userChanges : [ZMManagedObject : Set<String>] = [:]
    private var unreadMessages : [Notification.Name : Set<ZMMessage>] = [:]
    private var shouldStartObserving: Bool {
        return !isDisabled && !isInBackground
    }
    
    private var isObserving : Bool = true {
        didSet {
            guard oldValue != isObserving else { return }
            
            isObserving ? startObserving() : stopObserving()
        }
    }
    
    private var isInBackground: Bool = false {
        didSet {
            isObserving = shouldStartObserving
        }
    }
    
    /// If `isDisabled` is true no change notifications will be generated
    @objc public var isDisabled: Bool = false {
        didSet {
            isObserving = shouldStartObserving
        }
    }
    
    public init(managedObjectContext: NSManagedObjectContext) {
        assert(managedObjectContext.zm_isUserInterfaceContext, "NotificationDispatcher needs to be initialized with uiMOC")
        self.managedObjectContext = managedObjectContext
        let classIdentifiers : [String] = [ZMConversation.classIdentifier,
                                           ZMUser.classIdentifier,
                                           ZMConnection.classIdentifier,
                                           UserClient.classIdentifier,
                                           ZMMessage.classIdentifier,
                                           ZMClientMessage.classIdentifier,
                                           ZMAssetClientMessage.classIdentifier,
                                           ZMSystemMessage.classIdentifier,
                                           Reaction.classIdentifier,
                                           ZMGenericMessageData.classIdentifier,
                                           Team.classIdentifier,
                                           Member.classIdentifier,
                                           Label.classIdentifier,
                                           ParticipantRole.classIdentifier]
        self.affectingKeysStore = DependencyKeyStore(classIdentifiers : classIdentifiers)
        self.snapshotCenter = SnapshotCenter(managedObjectContext: managedObjectContext)
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotificationDispatcher.objectsDidChange(_:)),
            name:.NSManagedObjectContextObjectsDidChange,
            object: self.managedObjectContext)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NotificationDispatcher.contextDidSave(_:)),
            name:.NSManagedObjectContextDidSave,
            object: self.managedObjectContext)
        self.notificationTokens.append(NotificationInContext.addObserver(
            name: .NonCoreDataChangeInManagedObject,
            context: self.managedObjectContext.notificationContext)
        { [weak self] note in
            self?.nonCoreDataChange(note)
        })
    }

    deinit {
        assert(self.tornDown)
    }
    
    /// To receive and process changeInfos, call this method to add yourself as an consumer
    @objc public func addChangeInfoConsumer(_ consumer: ChangeInfoConsumer) {
        let boxed = UnownedNSObject(consumer as! NSObject)
        self.changeInfoConsumers.append(boxed)
    }
    
    /// Call this when the application enters the background to stop sending notifications and clear current changes
    @objc func applicationDidEnterBackground() {
        self.isInBackground = true
    }
    
    /// Call this when the application will enter the foreground to start sending notifications again
    @objc func applicationWillEnterForeground() {
        self.isInBackground = false
    }
        
    private func stopObserving() {
        self.unreadMessages = [:]
        self.allChanges = [:]
        self.userChanges = [:]
        self.snapshotCenter.clearAllSnapshots()
        self.allChangeInfoConsumers.forEach{$0.stopObserving()}
    }
    
    private func startObserving() {
        self.allChangeInfoConsumers.forEach{$0.startObserving()}
    }
    
    /// This is called when objects in the uiMOC change
    /// Might be called several times in between saves
    @objc func objectsDidChange(_ note: Notification){
        guard isObserving else { return }
        self.forwardChangesToConversationListObserver(note: note)
        self.process(note: note)
    }
    
    /// This is called when the uiMOC saved
    @objc func contextDidSave(_ note: Notification){
        guard isObserving else { return }
        self.fireAllNotifications()
    }
    
    /// This will be called if a change to an object does not cause a change in Core Data, e.g. downloading the asset and adding it to the cache
    func nonCoreDataChange(_ note: NotificationInContext){
        guard isObserving,
              let changedKeys = note.changedKeys,
              let object = note.object as? ZMManagedObject else { return }
        
        let change = Changes(changedKeys: Set(changedKeys))
        let objectAndChangedKeys = [object: change]
        self.allChanges = self.allChanges.merged(with: objectAndChangedKeys)
        // Fire notifications only if there won't be a save happening anytime soon
        if !managedObjectContext.zm_hasChanges {
            self.fireAllNotifications()
        } else { // make sure we will save eventually, even if we forgot to save somehow
            managedObjectContext.enqueueDelayedSave()
        }
    }
    
    /// Forwards inserted and deleted conversations to the conversationList observer to update lists accordingly
    internal func forwardChangesToConversationListObserver(note: Notification) {
        guard let userInfo = note.userInfo as? [String: Any] else { return }
        
        let insertedLabels = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.compactMap{$0 as? Label} ?? []
        let deletedLabels = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.compactMap{$0 as? Label} ?? []
        self.conversationListObserverCenter.folderChanges(inserted: insertedLabels, deleted: deletedLabels)
        
        let insertedConversations = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.compactMap{$0 as? ZMConversation} ?? []
        let deletedConversations = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.compactMap{$0 as? ZMConversation} ?? []
        self.conversationListObserverCenter.conversationsChanges(inserted: insertedConversations, deleted: deletedConversations)
    }
    
    /// Call this from syncStrategy AFTER merging the changes from syncMOC into uiMOC
    public func didMergeChanges(_ changedObjectIDs: Set<NSManagedObjectID>) {
        guard isObserving else { return }
        let changedObjects : [ZMManagedObject] = changedObjectIDs.compactMap{(try? managedObjectContext.existingObject(with: $0)) as? ZMManagedObject}
        self.extractChanges(from: Set(changedObjects))
        self.fireAllNotifications()
    }
    
    func process(note: Notification) {
        guard let userInfo = note.userInfo as? [String : Any] else { return }

        let updatedObjects = self.extractObjects(for: NSUpdatedObjectsKey, from: userInfo)
        let refreshedObjects = self.extractObjects(for: NSRefreshedObjectsKey, from: userInfo)
        let insertedObjects = self.extractObjects(for: NSInsertedObjectsKey, from: userInfo)
        let deletedObjects = self.extractObjects(for: NSDeletedObjectsKey, from: userInfo)
        
        self.snapshotCenter.createSnapshots(for: insertedObjects)
        
        let allUpdated = updatedObjects.union(refreshedObjects)
        self.extractChanges(from: allUpdated)
        self.extractChangesCausedByInsertionOrDeletion(of: insertedObjects)
        self.extractChangesCausedByInsertionOrDeletion(of: deletedObjects)

        self.checkForUnreadMessages(insertedObjects: insertedObjects, updatedObjects:updatedObjects )
        
        self.userChanges = [:]
    }
    
    func extractObjects(for key: String, from userInfo: [String : Any]) -> Set<ZMManagedObject> {
        guard let objects = userInfo[key] else { return Set() }
        if let expectedObjects = objects as? Set<ZMManagedObject> {
            return expectedObjects
        }
        else if let mappedObjects = (objects as? Set<NSObject>) {
            zmLog.warn("Unable to cast userInfo content to Set of ZMManagedObject. Is there a new entity that does not inherit form it?")
            return Set(mappedObjects.compactMap{$0 as? ZMManagedObject})
        }
        assertionFailure("Uh oh... Unable to map objects in userInfo")
        return Set()
    }
    
    /// Checks if any messages that were inserted or updated are unread and fired notifications for those
    func checkForUnreadMessages(insertedObjects: Set<ZMManagedObject>, updatedObjects: Set<ZMManagedObject>){
        let unreadUnsent : [ZMMessage] = updatedObjects.compactMap{
            guard let msg = $0 as? ZMMessage else { return nil}
            return (msg.deliveryState == .failedToSend) ? msg : nil
        }
        let (newUnreadMessages, newUnreadKnocks) = insertedObjects.reduce(([ZMMessage](),[ZMMessage]())) {
            guard let msg = $1 as? ZMMessage, msg.isUnreadMessage else { return $0 }
            var (messages, knocks) = $0
            if msg.knockMessageData == nil {
                messages.append(msg)
            } else {
                knocks.append(msg)
            }
            return (messages, knocks)
        }
        
        self.updateExisting(name: .NewUnreadUnsentMessage, newSet: unreadUnsent)
        self.updateExisting(name: .NewUnreadMessage, newSet: newUnreadMessages)
        self.updateExisting(name: .NewUnreadKnock, newSet: newUnreadKnocks)
    }
    
    func updateExisting(name: Notification.Name, newSet: [ZMMessage]) {
        let existingUnreadUnsent = self.unreadMessages[name]
        self.unreadMessages[name] = existingUnreadUnsent?.union(newSet) ?? Set(newSet)
    }
    
    /// Extracts changes from the updated objects
    func extractChanges(from changedObjects: Set<ZMManagedObject>) {
        
        func getChangedKeysSinceLastSave(object: ZMManagedObject) -> Set<String> {
            var changedKeys = Set(object.changedValues().keys)
            if changedKeys.count == 0 || object.isFault  {
                // If the object is a fault, calling changedValues() will return an empty set
                // Luckily we created a snapshot of the object before the merge happend which we can use to compare the values
                changedKeys = self.snapshotCenter.extractChangedKeysFromSnapshot(for: object)
            } else {
                self.snapshotCenter.updateSnapshot(for: object)
            }
            if let knownKeys = self.userChanges[object] {
                changedKeys = changedKeys.union(knownKeys)
            }
            return changedKeys
        }
        
        // Check for changed keys and affected keys
        
        let changes : [ZMManagedObject: Changes] = changedObjects.mapToDictionary{ object in
            // (1) Get all the changed keys since last Save
            let changedKeys = getChangedKeysSinceLastSave(object: object)
            guard changedKeys.count > 0 else { return nil }
            
            // (2) Get affected changes
            self.extractChangesCausedByChangeInObjects(updatedObject: object, knownKeys: changedKeys)
            
            // (3) Map the changed keys to affected keys, remove the ones that we are not reporting
            let affectedKeys = changedKeys.map{affectingKeysStore.observableKeysAffectedByValue(object.classIdentifier, key: $0)}
                                          .reduce(Set()){$0.union($1)}
            guard affectedKeys.count > 0 else { return nil }
            return Changes(changedKeys: affectedKeys)
        }
        // (4) Merge the changes with the other ones
        self.allChanges = self.allChanges.merged(with: changes)
    }
    
    /// Get all changes that resulted from other objects through dependencies (e.g. user.name -> conversation.displayName)
    func extractChangesCausedByChangeInObjects(updatedObject:  ZMManagedObject, knownKeys : Set<String>)
    {
        // (1) All Updates in other objects resulting in changes on others
        // e.g. changing a users name affects the conversation displayName
        guard let object = updatedObject as? SideEffectSource else { return }
        let changedObjectsAndKeys = object.affectedObjectsAndKeys(keyStore: affectingKeysStore, knownKeys: knownKeys)
        self.allChanges = self.allChanges.merged(with: changedObjectsAndKeys)
    }
    
    /// Get all changes that resulted from other objects through dependencies (e.g. user.name -> conversation.displayName)
    func extractChangesCausedByInsertionOrDeletion(of objects: Set<ZMManagedObject>)
    {
        // All inserts or deletes of other objects resulting in changes in others
        // e.g. inserting a user affects the conversation displayName
        objects.forEach{ (obj) in
            guard let object = obj as? SideEffectSource else { return }
            let changedObjectsAndKeys = object.affectedObjectsForInsertionOrDeletion(keyStore: affectingKeysStore)
            self.allChanges = self.allChanges.merged(with: changedObjectsAndKeys)
        }
    }
    
    func fireAllNotifications(){
        let changes = allChanges
        let unreads = unreadMessages
        
        self.unreadMessages = [:]
        self.allChanges = [:]
        
        var allChangeInfos : [ClassIdentifier: [ObjectChangeInfo]] = [:]
        changes.forEach{ (object, changedKeys) in
            guard let notificationName = (object as? ObjectInSnapshot)?.notificationName,
                let changeInfo = ObjectChangeInfo.changeInfo(for: object, changes: changedKeys)
                else { return }
            
            let classIdentifier = object.classIdentifier
            NotificationInContext(name: notificationName,
                                  context: self.managedObjectContext.notificationContext,
                                  object: object,
                                  changeInfo: changeInfo)
                .post()
            
            var previousChanges = allChangeInfos[classIdentifier] ?? []
            previousChanges.append(changeInfo)
            allChangeInfos[classIdentifier] = previousChanges
        }
        self.forwardNotificationToObserverCenters(changeInfos: allChangeInfos)
        self.fireNewUnreadMessagesNotifications(unreadMessages: unreads)
    }
    
    
    /// Fire all new unread notifications
    private func fireNewUnreadMessagesNotifications(unreadMessages: [Notification.Name : Set<ZMMessage>]){
        unreadMessages.forEach{ (notificationName, messages) in
            guard messages.count > 0 else { return }
            guard let changeInfo = ObjectChangeInfo.changeInfoForNewMessageNotification(with: notificationName, changedMessages: messages) else {
                zmLog.warn("Did you forget to add the mapping for that?")
                return
            }
            NotificationInContext(name: notificationName,
                                  context: self.managedObjectContext.notificationContext,
                                  changeInfo: changeInfo)
                .post()
        }
    }
    
    func forwardNotificationToObserverCenters(changeInfos: [ClassIdentifier: [ObjectChangeInfo]]){
        self.allChangeInfoConsumers.forEach{
            $0.objectsDidChange(changes: changeInfos)
        }
    }
}

extension NotificationDispatcher: TearDownCapable {
    public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        self.notificationTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        self.notificationTokens = []
        self.conversationListObserverCenter.tearDown()
        self.tornDown = true
    }
}

extension NotificationDispatcher {

    /// - note: This can safely be called from any thread as it will switch to uiContext internally
    public static func notifyNonCoreDataChanges(objectID: NSManagedObjectID, changedKeys: [String], uiContext: NSManagedObjectContext) {
        uiContext.performGroupedBlock {
            guard let uiMessage = try? uiContext.existingObject(with: objectID) else { return }
            
            NotificationInContext(name: .NonCoreDataChangeInManagedObject,
                                  context: uiContext.notificationContext,
                                  object: uiMessage,
                                  changedKeys: changedKeys)
                .post()
        }
    }
}

