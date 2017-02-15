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

private var zmLog = ZMSLog(tag: "MessageWindowObserverCenter")

extension Notification.Name {
    
    static let ZMConversationMessageWindowScrolled = Notification.Name("ZMConversationMessageWindowScrolledNotification")
    static let ZMConversationMessageWindowCreated = Notification.Name("ZMConversationMessageWindowCreatedNotification")
    static let MessageWindowDidChange = Notification.Name("MessageWindowDidChangeNotification")

}



extension NSManagedObjectContext {

    static let MessageWindowObserverCenterKey = "MessageWindowObserverCenterKey"
    
    public var messageWindowObserverCenter : MessageWindowObserverCenter {
        assert(zm_isUserInterfaceContext, "MessageWindowObserverCenter does not exist in syncMOC")
        
        if let observer = userInfo[NSManagedObjectContext.MessageWindowObserverCenterKey] as? MessageWindowObserverCenter {
            return observer
        }
        
        let newObserver = MessageWindowObserverCenter()
        userInfo[NSManagedObjectContext.MessageWindowObserverCenterKey] = newObserver
        return newObserver
    }
}

@objc final public class MessageWindowObserverCenter : NSObject, ChangeInfoConsumer {
    
    var windowSnapshot : MessageWindowSnapshot?
    
    @objc public func windowDidScroll(_ window: ZMConversationMessageWindow) {
        if let snapshot = windowSnapshot, snapshot.conversationWindow == window {
            snapshot.windowDidScroll()
        } else {
            zmLog.debug("WindowDidScroll - Creating snapshot for window \(window), removing snapshot for old window in conversation: \(windowSnapshot?.conversation)")
            windowSnapshot = MessageWindowSnapshot(window: window)
        }
    }
    
    /// Creates a snapshot of the window and updates the window when changes occur
    /// It automatically tears down the old window snapshot, since there should only be one window open at any time
    /// Call this when initializing a new message window
    @objc public func windowWasCreated(_ window: ZMConversationMessageWindow) {
        if let snapshot = windowSnapshot, snapshot.conversationWindow == window {
            zmLog.debug("WindowWasCreated - Using existing snapshot for window \(window)")
            return
        }
        zmLog.debug("WindowWasCreated - Creating snapshot for window \(window), removing snapshot for old window \(windowSnapshot?.conversationWindow) in conversation: \(windowSnapshot?.conversation)")
        windowSnapshot = MessageWindowSnapshot(window: window)
    }
    
    /// Removes the windowSnapshot if there is one
    /// Call this when tearing down or deallocating the messageWindow
    @objc public func removeMessageWindow(_ window: ZMConversationMessageWindow) {
        if let snapshot = windowSnapshot, snapshot.conversationWindow != window {
            return
        }
        zmLog.debug("Removing snapshot for window \(window)")
        windowSnapshot = nil
    }
    
    public func objectsDidChange(changes: [ClassIdentifier : [ObjectChangeInfo]]) {
        guard let snapshot = windowSnapshot else {
            zmLog.debug("ObjectsDidChange, but no snapshot to update")
            return
        }
        changes.values.forEach{
            if let convChanges = $0 as? [ConversationChangeInfo] {
                zmLog.debug("Conversations did change: \n \(convChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                convChanges.forEach{snapshot.conversationDidChange($0)}
            }
            if let userChanges = $0 as? [UserChangeInfo] {
                zmLog.debug("Users did change: \n \(userChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                userChanges.forEach{snapshot.userDidChange(changeInfo: $0)}
            }
            if let messageChanges = $0 as? [MessageChangeInfo] {
                zmLog.debug("Messages did change: \n \(messageChanges.map{$0.customDebugDescription}.joined(separator: "\n"))")
                messageChanges.forEach{snapshot.messageDidChange($0)}
            }
        }
        
        snapshot.fireNotifications()
    }
    
    public func applicationDidEnterBackground() {
        // do nothing
    }
    
    public func applicationWillEnterForeground() {
        windowSnapshot?.applicationWillEnterForeground()
    }
}


class MessageWindowSnapshot : NSObject, ZMConversationObserver, ZMMessageObserver {

    fileprivate var state : SetSnapshot
    
    public weak var conversationWindow : ZMConversationMessageWindow?
    fileprivate var conversation : ZMConversation? {
        return conversationWindow?.conversation
    }
    
    fileprivate var shouldRecalculate : Bool = false
    fileprivate var updatedMessages : [ZMMessage] = []
    fileprivate var messageChangeInfos : [MessageChangeInfo] = []
    fileprivate var userChanges: [NSManagedObjectID : UserChangeInfo] = [:]
    fileprivate var userIDsInWindow : Set<NSManagedObjectID> {
        if tempUserIDsInWindow == nil {
            tempUserIDsInWindow = (state.set.array as? [ZMMessage] ?? []).reduce(Set()){$0.union($1.allUserIDs)}
        }
        return tempUserIDsInWindow!
    }
    fileprivate var tempUserIDsInWindow : Set<NSManagedObjectID>? = nil
    
    
    var isTornDown : Bool = false
    
    fileprivate var currentlyFetchingMessages = false
    
    init(window: ZMConversationMessageWindow) {
        self.conversationWindow = window
        self.state = SetSnapshot(set: window.messages, moveType: .uiCollectionView)
        super.init()
    }
    
    func windowDidScroll() {
        computeChanges()
    }
    
    func fireNotifications() {
        if(shouldRecalculate || updatedMessages.count > 0) {
            computeChanges()
        }
        userChanges = [:]
    }
    
    // MARK: Forwarding Changes
    /// Processes conversationChangeInfo for conversations in window when messages changed
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard let conversation = conversation, changeInfo.conversation == conversation else { return }
        if(changeInfo.messagesChanged || changeInfo.clearedChanged) {
            shouldRecalculate = true
            zmLog.debug("Recalculating window due to conversation change \(changeInfo.customDebugDescription)")
        }
    }
    
    /// Processes messageChangeInfos for messages in window when messages changed
    func messageDidChange(_ change: MessageChangeInfo) {
        guard let window = conversationWindow, window.messages.contains(change.message) else { return }
        
        updatedMessages.append(change.message)
        messageChangeInfos.append(change)
    }

    /// Processes messageChangeInfos for users who's messages are currently in the window
    func userDidChange(changeInfo: UserChangeInfo) {
        guard let user = changeInfo.user as? ZMUser,
             (changeInfo.nameChanged || changeInfo.accentColorValueChanged || changeInfo.imageMediumDataChanged || changeInfo.imageSmallProfileDataChanged)
        else { return }
        
        guard userIDsInWindow.contains(user.objectID) else { return }
        
        userChanges[user.objectID] = changeInfo
        shouldRecalculate = true
        zmLog.debug("Recalculating window due to user change \(changeInfo.customDebugDescription)")
    }
    
    
    // MARK: Change computing
    /// Compute the changes, update window and notify observers
    fileprivate func computeChanges() {
        guard let window = conversationWindow else { return }
        defer {
            updatedMessages = []
            shouldRecalculate = false
        }
        
        // Recalculate message window
        window.recalculateMessages()
        
        // Calculate window changes
        let currentlyUpdatedMessages = updatedMessages
        let updatedSet = NSOrderedSet(array: currentlyUpdatedMessages.filter({$0.conversation === window.conversation}))
        
        var changeInfo : MessageWindowChangeInfo?
        if let newStateUpdate = state.updatedState(updatedSet, observedObject: window, newSet: window.messages) {
            state = newStateUpdate.newSnapshot
            changeInfo = MessageWindowChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
            tempUserIDsInWindow = nil
        }
        
        // Notify observers
        postNotification(windowChangeInfo: changeInfo, for: window)
    }
    
    /// We receive UserChangeInfos separately and need to merge them with the messageChangeInfo in order to include userChanges
    /// This is necessary because there is no coreData relationship set between user -> messages (only the reverse) and it would be very expensive to notify for changes of messages due to a user change otherwise
    func updateMessageChangeInfos(window: ZMConversationMessageWindow) {
        messageChangeInfos.forEach{
            guard let user = $0.message.sender, let userChange = userChanges.removeValue(forKey:user.objectID) else { return }
            $0.changeInfos["userChanges"] = userChange
        }
        
        guard userChanges.count > 0, let messages = window.messages.array as? [ZMMessage] else { return }
        
        let messagesToUserIDs = messages.mapToDictionary{$0.allUserIDs}
        userChanges.forEach{ (objectID, change) in
            messagesToUserIDs.forEach{ (message, userIDs) in
                guard userIDs.contains(objectID) else { return }
                
                let changeInfo = MessageChangeInfo(object: message)
                changeInfo.changeInfos["userChanges"] = change
                messageChangeInfos.append(changeInfo)
            }
        }
    }
    
    /// Updates the messageChangeInfos and posts both the passed in WindowChangeInfo as well as the messageChangeInfos
    func postNotification(windowChangeInfo: MessageWindowChangeInfo?, for window: ZMConversationMessageWindow){
        defer {
            userChanges = [:]
            messageChangeInfos = []
        }

        updateMessageChangeInfos(window: window)
        
        var userInfo = [String : Any]()
        if messageChangeInfos.count > 0 {
            userInfo["messageChangeInfos"] = messageChangeInfos
        }
        if let changeInfo = windowChangeInfo {
            userInfo["messageWindowChangeInfo"] = changeInfo
        }
        NotificationCenter.default.post(name: .MessageWindowDidChange, object: window, userInfo: userInfo)
        zmLog.debug(logMessage(for: messageChangeInfos, windowChangeInfo: windowChangeInfo))
    }
    
    
    public func applicationWillEnterForeground() {
        shouldRecalculate = true
        computeChanges()
    }
    
    func logMessage(for messageChangeInfos: [MessageChangeInfo], windowChangeInfo: MessageWindowChangeInfo?) -> String {
        var message = "Posting notification with messageChangeInfos: \n"
        message.append(messageChangeInfos.map{$0.customDebugDescription}.joined(separator: "\n"))
        
        guard let changeInfo = windowChangeInfo else { return message }
        message.append("\n MessageWindowChangeInfo: \(changeInfo.description)")
        return message
    }
}

extension ZMSystemMessage {

    override var allUserIDs : Set<NSManagedObjectID> {
        let allIDs = super.allUserIDs
        return allIDs.union((users.union(addedUsers).union(removedUsers)).map{$0.objectID})
    }
}

extension ZMMessage {
    
    var allUserIDs : Set<NSManagedObjectID> {
        guard let sender = sender else { return Set()}
        return Set([sender.objectID])
    }
}

