//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import GenericMessageProtocol
import WireDataModel

let IsTypingKey = "isTyping"

let StatusKey = "status"
let StoppedKey = "stopped"
let StartedKey = "started"

@objc
public extension ZMConversation {

    // Used for handling remote notifications
    static let typingNotificationName = Notification.Name(rawValue: "ZMTypingNotification")

    // Used for handling local notifications
    static let typingChangeNotificationName = Notification.Name(rawValue: "ZMTypingChangeNotification")

}

public struct TypingEvent {

    let date: Date
    let objectID: NSManagedObjectID
    let isTyping: Bool

    static func typingEvent(
        with objectID: NSManagedObjectID,
        isTyping: Bool,
        ifDifferentFrom other: TypingEvent?
    ) -> TypingEvent? {
        let newEvent = TypingEvent(date: Date(), objectID: objectID, isTyping: isTyping)
        if let other, newEvent.isEqual(other: other) {
            return nil
        }
        return newEvent
    }

    func isEqual(other: TypingEvent) -> Bool {
        isTyping == other.isTyping &&
            objectID.isEqual(other.objectID) &&
            fabs(date.timeIntervalSince(other.date)) < Typing.defaultTimeout
    }

}

class TypingEventQueue {

    /// conversations with their current isTyping state
    var conversations: [NSManagedObjectID: Bool] = [:]

    /// conversations that started typing, but never ended
    var unbalancedConversations: Set<NSManagedObjectID> = Set()

    /// last event that has been requested
    var lastSentTypingEvent: TypingEvent?

    /// Adds the conversation to the "queue"
    /// If `isTyping` is true, it turns all other conversation events to endTyping events
    func addItem(conversationID: NSManagedObjectID, isTyping: Bool) {
        if isTyping {
            // end all previous typings
            conversations.forEach {
                conversations[$0.key] = false
            }
            unbalancedConversations.forEach {
                conversations[$0] = false
            }
            unbalancedConversations.insert(conversationID)
        } else {
            unbalancedConversations.remove(conversationID)
        }
        conversations[conversationID] = isTyping
    }

    /// Returns the next typing event that is different from the last sent typing event
    func nextEvent() -> TypingEvent? {
        var event: TypingEvent?

        while event == nil, let (convObjectID, isTyping) = conversations.popFirst() {
            event = TypingEvent.typingEvent(
                with: convObjectID,
                isTyping: isTyping,
                ifDifferentFrom: lastSentTypingEvent
            )
        }
        if let anEvent = event {
            lastSentTypingEvent = anEvent
        }
        return event
    }

    func clear(conversationID: NSManagedObjectID) {
        conversations.removeValue(forKey: conversationID)
    }
}

public class TypingStrategy: AbstractRequestStrategy, TearDownCapable {

    fileprivate var typing: Typing!
    fileprivate let typingEventQueue = TypingEventQueue()
    fileprivate var tornDown: Bool = false
    fileprivate var observers: [Any] = []
    private let localDomain: String?
    private let isFederationEnabled: Bool

    @available(*, unavailable)
    override init(withManagedObjectContext moc: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        fatalError()
    }

    public convenience init(
        applicationStatus: ApplicationStatus,
        managedObjectContext: NSManagedObjectContext,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.init(
            applicationStatus: applicationStatus,
            syncContext: managedObjectContext,
            uiContext: managedObjectContext.zm_userInterface,
            typing: nil,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
    }

    init(
        applicationStatus: ApplicationStatus,
        syncContext: NSManagedObjectContext,
        uiContext: NSManagedObjectContext,
        typing: Typing?,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {
        self.typing = typing ?? Typing(uiContext: uiContext, syncContext: syncContext)
        self.localDomain = localDomain
        self.isFederationEnabled = isFederationEnabled
        super.init(withManagedObjectContext: syncContext, applicationStatus: applicationStatus)
        self.configuration = [
            .allowsRequestsWhileInBackground,
            .allowsRequestsWhileOnline
        ]

        observers.append(
            NotificationInContext.addObserver(
                name: ZMConversation.typingNotificationName,
                context: managedObjectContext.notificationContext,
                using: { [weak self] in self?.addConversationForNextRequest(note: $0) }
            )
        )

        observers.append(
            NotificationInContext.addObserver(
                name: ZMConversation.typingChangeNotificationName,
                context: managedObjectContext.notificationContext,
                using: { [weak self] in self?.addConversationForNextRequest(note: $0) }
            )
        )

        observers.append(
            NotificationInContext.addObserver(
                name: ZMConversation.clearTypingNotificationName,
                context: managedObjectContext.notificationContext,
                using: { [weak self] in
                    self?.shouldClearTypingForConversation(note: $0)
                }
            )
        )
    }

    deinit {
        assert(tornDown, "Need to tearDown TypingStrategy")
    }

    @objc
    fileprivate func addConversationForNextRequest(note: NotificationInContext) {
        guard let conversation = note.object as? ZMConversation, conversation.remoteIdentifier != nil
        else { return }

        if let isTyping = (note.userInfo[IsTypingKey] as? NSNumber)?.boolValue {
            add(conversation: conversation, isTyping: isTyping, clearIsTyping: false)
        }
    }

    @objc
    fileprivate func shouldClearTypingForConversation(note: NotificationInContext) {
        guard let conversation = note.object as? ZMConversation, conversation.remoteIdentifier != nil
        else { return }

        add(conversation: conversation, isTyping: false, clearIsTyping: true)
    }

    fileprivate func add(conversation: ZMConversation, isTyping: Bool, clearIsTyping: Bool) {
        guard conversation.remoteIdentifier != nil
        else { return }

        managedObjectContext.performGroupedBlock {
            if clearIsTyping {
                self.typingEventQueue.clear(conversationID: conversation.objectID)
                self.typingEventQueue.lastSentTypingEvent = nil
            } else {
                self.typingEventQueue.addItem(conversationID: conversation.objectID, isTyping: isTyping)
                RequestAvailableNotification.notifyNewRequestsAvailable(self)
            }
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let typingEvent = typingEventQueue.nextEvent(),
              let conversation = managedObjectContext.object(with: typingEvent.objectID) as? ZMConversation,
              let remoteIdentifier = conversation.remoteIdentifier
        else { return nil }

        let path: String
        switch apiVersion {
        case .v0, .v1, .v2:
            path = "/conversations/\(remoteIdentifier.transportString())/typing"

        case .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14:
            let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { localDomain }
            guard let domain else { return nil }
            path = "/conversations/\(domain)/\(remoteIdentifier.transportString())/typing"
        }

        let payload = [StatusKey: typingEvent.isTyping ? StartedKey : StoppedKey]
        let request = ZMTransportRequest(
            path: path,
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
        request.setDebugInformationTranscoder(self)

        return request
    }

    // MARK: - TearDownCapable

    public func tearDown() {
        typing.tearDown()
        typing = nil
        tornDown = true
        observers = []
    }
}

public extension TypingStrategy {

    static func notifyTranscoderThatUser(isTyping: Bool, in conversation: ZMConversation) {
        let userInfo = [IsTypingKey: NSNumber(value: isTyping)]
        NotificationInContext(
            name: ZMConversation.typingChangeNotificationName,
            context: conversation.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: userInfo
        )
        .post()
    }

    static func clearTranscoderStateForTyping(in conversation: ZMConversation) {
        NotificationInContext(
            name: ZMConversation.clearTypingNotificationName,
            context: conversation.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: nil
        )
        .post()
    }
}
