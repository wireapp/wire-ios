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

    public static let NonCoreDataChangeInManagedObject = Notification.Name("NonCoreDataChangeInManagedObject")
    
}


/// Creates an object that registers an observer in NSNotificationCenter
/// When this object is deallocated, it automatically unregisters from NSNotificationCenter
/// To receive notifications, make sure to hold a strong reference to this object
public class NotificationCenterObserverToken : NSObject {
    
    var token : AnyObject?
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    public init(name: NSNotification.Name, object: AnyObject? = nil, queue: OperationQueue? = nil, block: @escaping (_ note: Notification) -> Void) {
        token = NotificationCenter.default.addObserver(forName: name, object: object, queue: queue, using: block)
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
}


public typealias ClassIdentifier = String
typealias ObjectAndChanges = [ZMManagedObject : Changes]

@objc public protocol ChangeInfoConsumer : NSObjectProtocol {
    func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]])
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
}

extension ZMManagedObject {
    
    static var classIdentifier : String {
        return entityName()
    }
    
    var classIdentifier: String {
        return type(of: self).entityName()
    }
}

public class NotificationDispatcher : NSObject {

    private unowned var managedObjectContext: NSManagedObjectContext
    
    private var tornDown = false
    private let affectingKeysStore : DependencyKeyStore
    private var messageWindowObserverCenter : MessageWindowObserverCenter {
        return managedObjectContext.messageWindowObserverCenter
    }
    private var conversationListObserverCenter : ConversationListObserverCenter {
        return managedObjectContext.conversationListObserverCenter
    }
    private var searchUserObserverCenter: SearchUserObserverCenter {
        return managedObjectContext.searchUserObserverCenter
    }
    private let snapshotCenter: SnapshotCenter
    private var changeInfoConsumers = [UnownedNSObject]()
    private var allChangeInfoConsumers : [ChangeInfoConsumer] {
        var consumers = changeInfoConsumers.flatMap{$0.unbox as? ChangeInfoConsumer}
        consumers.append(messageWindowObserverCenter)
        consumers.append(searchUserObserverCenter)
        consumers.append(conversationListObserverCenter)
        return consumers
    }
    
    private var allChanges : [ZMManagedObject : Changes] = [:]
    private var userChanges : [ZMManagedObject : Set<String>] = [:]
    private var unreadMessages : [Notification.Name : Set<ZMMessage>] = [:]
    private var forwardChanges : Bool = true
    
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
                                           Reaction.classIdentifier,
                                           ZMGenericMessageData.classIdentifier]
        self.affectingKeysStore = DependencyKeyStore(classIdentifiers : classIdentifiers)
        self.snapshotCenter = SnapshotCenter(managedObjectContext: managedObjectContext)
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcher.objectsDidChange(_:)), name:.NSManagedObjectContextObjectsDidChange, object: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcher.contextDidSave(_:)), name:.NSManagedObjectContextDidSave, object: self.managedObjectContext)
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcher.nonCoreDataChange(_:)), name:.NonCoreDataChangeInManagedObject, object: nil)
    }
    
    public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        conversationListObserverCenter.tearDown()
        tornDown = true
    }
    
    deinit {
        assert(tornDown)
    }
    
    /// To receive and process changeInfos, call this method to add yourself as an consumer
    @objc public func addChangeInfoConsumer(_ consumer: ChangeInfoConsumer) {
        let boxed = UnownedNSObject(consumer as! NSObject)
        changeInfoConsumers.append(boxed)
    }
    
    /// Call this when the application enters the background to stop sending notifications and clear current changes
    @objc func applicationDidEnterBackground() {
        forwardChanges = false
        unreadMessages = [:]
        allChanges = [:]
        userChanges = [:]
        snapshotCenter.clearAllSnapshots()
        allChangeInfoConsumers.forEach{$0.applicationDidEnterBackground()}
    }
    
    /// Call this when the application will enter the foreground to start sending notifications again
    @objc func applicationWillEnterForeground() {
        forwardChanges = true
        allChangeInfoConsumers.forEach{$0.applicationWillEnterForeground()}
    }
    
    /// This is called when objects in the uiMOC change
    /// Might be called several times in between saves
    @objc func objectsDidChange(_ note: Notification){
        guard forwardChanges else { return }
        forwardChangesToConversationListObserver(note: note)
        process(note: note)
    }
    
    /// This is called when the uiMOC saved
    @objc func contextDidSave(_ note: Notification){
        guard forwardChanges else { return }
        fireAllNotifications()
    }
    
    /// This will be called if a change to an object does not cause a change in Core Data, e.g. downloading the asset and adding it to the cache
    @objc func nonCoreDataChange(_ note: Notification){
        guard forwardChanges else { return }
        guard let object = note.object as? ZMManagedObject,
              let changedKeys = (note.userInfo as? [String : [String]])?["changedKeys"]
        else { return }
        
        let change = Changes(changedKeys: Set(changedKeys))

        let objectAndChangedKeys = [object: change]
        allChanges = allChanges.merged(with: objectAndChangedKeys) 
        managedObjectContext.forceSaveOrRollback()
    }
    
    /// Forwards inserted and deleted conversations to the conversationList observer to update lists accordingly
    internal func forwardChangesToConversationListObserver(note: Notification) {
        guard let userInfo = note.userInfo as? [String: Any] else { return }
        
        let insertedObjects = (userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>)?.flatMap{$0 as? ZMConversation} ?? []
        let deletedObjects = (userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>)?.flatMap{$0 as? ZMConversation} ?? []
        conversationListObserverCenter.conversationsChanges(inserted: insertedObjects,
                                                            deleted: deletedObjects,
                                                            accumulated: false)
    }
    
    /// Call this from syncStrategy BEFORE merging the changes from syncMOC into uiMOC
    /// Get updated objects from notifications userInfo and map them to objectIDs
    /// After merging call `didMergeChanges()`
    public func willMergeChanges(_ changes: Set<NSManagedObjectID>){
        guard forwardChanges else { return }
        snapshotCenter.willMergeChanges(changes: changes)
    }
    
    /// Call this from syncStrategy AFTER merging the changes from syncMOC into uiMOC
    public func didMergeChanges() {
        guard forwardChanges else { return }
        fireAllNotifications()
        snapshotCenter.clearAllSnapshots()
    }
    
    func process(note: Notification) {
        guard let userInfo = note.userInfo as? [String : Any] else { return }

        let updatedObjects = extractObjects(for: NSUpdatedObjectsKey, from: userInfo)
        let refreshedObjects = extractObjects(for: NSRefreshedObjectsKey, from: userInfo)
        let insertedObjects = extractObjects(for: NSInsertedObjectsKey, from: userInfo)
        let deletedObjects = extractObjects(for: NSDeletedObjectsKey, from: userInfo)
        
        let updatedAndRefreshed : Set<ZMManagedObject> = updatedObjects.union(refreshedObjects)
        let existingUsers : [ZMUser] = updatedAndRefreshed.flatMap{$0 as? ZMUser}
        let usersWithNewName : Set<ZMManagedObject> = checkForDisplayNameUpdates(updatedUsers:  Set(existingUsers),
                                                          insertedUsers: Set(insertedObjects.flatMap{$0 as? ZMUser}),
                                                          deletedUsers: Set(deletedObjects.flatMap{$0 as? ZMUser}))
        let usersWithNewImage : Set<ZMManagedObject> = checkForChangedImages()
        
        let allUpdated = updatedAndRefreshed.union(usersWithNewName).union(usersWithNewImage)
        extractChanges(from: allUpdated)
        extractChangesCausedByInsertionOrDeletion(of: insertedObjects)
        extractChangesCausedByInsertionOrDeletion(of: deletedObjects)

        checkForUnreadMessages(insertedObjects: insertedObjects, updatedObjects:updatedObjects )
        
        userChanges = [:]
    }
    
    func extractObjects(for key: String, from userInfo: [String : Any]) -> Set<ZMManagedObject> {
        guard let objects = userInfo[key] else { return Set() }
        if let expectedObjects = objects as? Set<ZMManagedObject> {
            return expectedObjects
        }
        else if let mappedObjects = (objects as? Set<NSObject>) {
            zmLog.warn("Unable to cast userInfo content to Set of ZMManagedObject. Is there a new entity that does not inherit form it?")
            return Set(mappedObjects.flatMap{$0 as? ZMManagedObject})
        }
        assertionFailure("Uh oh... Unable to map objects in userInfo")
        return Set()
    }
    
    /// Checks if any messages that were inserted or updated are unread and fired notifications for those
    func checkForUnreadMessages(insertedObjects: Set<ZMManagedObject>, updatedObjects: Set<ZMManagedObject>){
        let unreadUnsent : [ZMMessage] = updatedObjects.flatMap{
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
        
        updateExisting(name: .NewUnreadUnsentMessage, newSet: unreadUnsent)
        updateExisting(name: .NewUnreadMessage, newSet: newUnreadMessages)
        updateExisting(name: .NewUnreadKnock, newSet: newUnreadKnocks)
    }
    
    func updateExisting(name: Notification.Name, newSet: [ZMMessage]) {
        let existingUnreadUnsent = unreadMessages[name]
        unreadMessages[name] = existingUnreadUnsent?.union(newSet) ?? Set(newSet)
    }
    
    /// Gets additional user changes from userImageCache
    func checkForChangedImages() -> Set<ZMUser> {
        let largeImageChanges = managedObjectContext.zm_userImageCache?.usersWithChangedLargeImage
        let largeImageUsers = extractUsersWithImageChange(objectIDs: largeImageChanges,
                                                          changedKey: "imageMediumData")
        let smallImageChanges = managedObjectContext.zm_userImageCache?.usersWithChangedSmallImage
        let smallImageUsers = extractUsersWithImageChange(objectIDs: smallImageChanges,
                                                          changedKey: "imageSmallProfileData")
        managedObjectContext.zm_userImageCache?.usersWithChangedLargeImage = []
        managedObjectContext.zm_userImageCache?.usersWithChangedSmallImage = []
        return smallImageUsers.union(largeImageUsers)
    }
    
    
    func extractUsersWithImageChange(objectIDs: [NSManagedObjectID]?, changedKey: String) -> Set<ZMUser> {
        guard let objectIDs = objectIDs else { return Set() }
        var users = Set<ZMUser>()
        objectIDs.forEach { objectID in
            guard let user = (try? managedObjectContext.existingObject(with: objectID)) as? ZMUser else { return }
            var newValue = userChanges[user] ?? Set()
            newValue.insert(changedKey)
            userChanges[user] = newValue
            users.insert(user)
        }
        return users
    }
    
    /// Gets additional changes from UserDisplayNameGenerator
    func checkForDisplayNameUpdates(updatedUsers: Set<ZMUser>, insertedUsers: Set<ZMUser>, deletedUsers: Set<ZMUser>) -> Set<ZMUser> {
        let changedUsers = managedObjectContext.updateNameGenerator(updatedUsers: updatedUsers,
                                                                    insertedUsers: insertedUsers,
                                                                    deletedUsers: deletedUsers)
        changedUsers.forEach{ user in
            var newValue = userChanges[user] ?? Set()
            newValue.insert("displayName")
            userChanges[user] = newValue
        }
        return changedUsers
    }
    
    /// Extracts changes from the updated objects
    func extractChanges(from changedObjects: Set<ZMManagedObject>) {
        
        func getChangedKeysSinceLastSave(object: ZMManagedObject) -> Set<String> {
            var changedKeys = Set(object.changedValues().keys)
            if changedKeys.count == 0 || object.isFault  {
                // If the object is a fault, calling changedValues() will return an empty set
                // Luckily we created a snapshot of the object before the merge happend which we can use to compare the values
                changedKeys = snapshotCenter.extractChangedKeysFromSnapshot(for: object)
            } else {
                snapshotCenter.removeSnapshot(for:object)
            }
            if let knownKeys = userChanges[object] {
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
            extractChangesCausedByChangeInObjects(updatedObject: object, knownKeys: changedKeys)
            
            // (3) Map the changed keys to affected keys, remove the ones that we are not reporting
            let affectedKeys = changedKeys.map{affectingKeysStore.observableKeysAffectedByValue(object.classIdentifier, key: $0)}
                                          .reduce(Set()){$0.union($1)}
            guard affectedKeys.count > 0 else { return nil }
            return Changes(changedKeys: affectedKeys)
        }
        // (4) Merge the changes with the other ones
        allChanges = allChanges.merged(with: changes)
    }
    
    /// Get all changes that resulted from other objects through dependencies (e.g. user.name -> conversation.displayName)
    func extractChangesCausedByChangeInObjects(updatedObject:  ZMManagedObject, knownKeys : Set<String>)
    {
        // (1) All Updates in other objects resulting in changes on others
        // e.g. changing a users name affects the conversation displayName
        guard let object = updatedObject as? SideEffectSource else { return }
        let changedObjectsAndKeys = object.affectedObjectsAndKeys(keyStore: affectingKeysStore, knownKeys: knownKeys)
        allChanges = allChanges.merged(with: changedObjectsAndKeys)
    }
    
    /// Get all changes that resulted from other objects through dependencies (e.g. user.name -> conversation.displayName)
    func extractChangesCausedByInsertionOrDeletion(of objects: Set<ZMManagedObject>)
    {
        // All inserts or deletes of other objects resulting in changes in others
        // e.g. inserting a user affects the conversation displayName
        objects.forEach{ (obj) in
            guard let object = obj as? SideEffectSource else { return }
            let changedObjectsAndKeys = object.affectedObjectsForInsertionOrDeletion(keyStore: affectingKeysStore)
            allChanges = allChanges.merged(with: changedObjectsAndKeys)
        }
    }
    
    func fireAllNotifications(){
        var allChangeInfos : [ClassIdentifier: [ObjectChangeInfo]] = [:]
        allChanges.forEach{ (object, changedKeys) in
            guard let notificationName = (object as? ObjectInSnapshot)?.notificationName,
                let changeInfo = ObjectChangeInfo.changeInfo(for: object, changes: changedKeys)
                else { return }
            
            let classIdentifier = object.classIdentifier
            let notification = Notification(name: notificationName, object: object, userInfo: ["changeInfo" : changeInfo])
            NotificationCenter.default.post(notification)
            var previousChanges = allChangeInfos[classIdentifier] ?? []
            previousChanges.append(changeInfo)
            allChangeInfos[classIdentifier] = previousChanges
        }
        forwardNotificationToObserverCenters(changeInfos: allChangeInfos)
        fireNewUnreadMessagesNotifications()
        unreadMessages = [:]
        allChanges = [:]
    }
    
    
    /// Fire all new unread notifications
    func fireNewUnreadMessagesNotifications(){
        unreadMessages.forEach{ (notificationName, messages) in
            guard messages.count > 0 else { return }
            guard let changeInfo = ObjectChangeInfo.changeInfoforNewMessageNotification(with: notificationName, changedMessages: messages) else {
                zmLog.warn("Did you forget to add the mapping for that?")
                return
            }
            let notification = Notification(name: notificationName, object:nil, userInfo: ["changeInfo" : changeInfo])
            NotificationCenter.default.post(notification)
        }
    }
    
    func forwardNotificationToObserverCenters(changeInfos: [ClassIdentifier: [ObjectChangeInfo]]){
        allChangeInfoConsumers.forEach{
            $0.objectsDidChange(changes: changeInfos)
        }
    }
}

extension NotificationDispatcher {

    
    public static func notifyNonCoreDataChanges(objectID: NSManagedObjectID, changedKeys: [String], uiContext: NSManagedObjectContext) {
        uiContext.performGroupedBlock {
            guard let uiMessage = try? uiContext.existingObject(with: objectID) else { return }
            NotificationCenter.default.post(name: .NonCoreDataChangeInManagedObject,
                                            object: uiMessage,
                                            userInfo: ["changedKeys" : changedKeys])
        }
    }
}
