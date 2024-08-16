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

@objc extension ZMUserSession {

    // MARK: - Foreground Actions

    public func acceptConnectionRequest(with userInfo: NotificationUserInfo, completionHandler: @escaping () -> Void) {

        guard let senderID = userInfo.senderID,
              let sender = ZMUser.fetch(with: senderID, in: managedObjectContext),
              let conversation = sender.oneOnOneConversation
        else { return }

        sender.accept(completion: { [weak self] _ in
            self?.showConversation(conversation)
            completionHandler()
        })
    }

    public func acceptCall(with userInfo: NotificationUserInfo, completionHandler: @escaping () -> Void) {

        guard let conversation = userInfo.conversation(in: managedObjectContext) else { return }

        defer {
            showConversation(conversation)
            completionHandler()
        }

        guard let callState = conversation.voiceChannel?.state else { return }

        if case let .incoming(video: video, shouldRing: _, degraded: _) = callState, callCenter?.activeCallConversations(in: self).count == 0 {
            _ = conversation.voiceChannel?.join(video: video, userSession: self)
        }
    }

    func showContent(for userInfo: NotificationUserInfo) {

        guard let conversation = userInfo.conversation(in: managedObjectContext) else {
            sessionManager?.showConversationList(in: self)
            return
        }

        guard let message = userInfo.message(in: conversation, managedObjectContext: managedObjectContext) as? ZMClientMessage else {
            return showConversation(conversation)
        }

        if let textMessageData = message.textMessageData, textMessageData.isMentioningSelf {
            showConversation(conversation, at: conversation.firstUnreadMessageMentioningSelf)
        } else {
            showConversation(conversation, at: message)
        }
    }

    fileprivate func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage? = nil) {
        sessionManager?.showConversation(conversation, at: message, in: self)
    }

    // MARK: - Background Actions

    public func ignoreCall(with userInfo: NotificationUserInfo, completionHandler: @escaping () -> Void) {
        guard let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "IgnoreCall Action Handler") else {
            return
        }

        let conversation = userInfo.conversation(in: managedObjectContext)

        managedObjectContext.perform {
            conversation?.voiceChannel?.leave(userSession: self, completion: nil)
            BackgroundActivityFactory.shared.endBackgroundActivity(activity)
            completionHandler()
        }
    }

    public func muteConversation(with userInfo: NotificationUserInfo, completionHandler: @escaping () -> Void) {
        guard let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "Mute Conversation Action Handler") else {
            return
        }

        let conversation = userInfo.conversation(in: managedObjectContext)

        managedObjectContext.perform {
            conversation?.mutedMessageTypes = .all
            self.managedObjectContext.saveOrRollback()
            BackgroundActivityFactory.shared.endBackgroundActivity(activity)
            completionHandler()
        }
    }

    public  func reply(with userInfo: NotificationUserInfo, message: String, completionHandler: @escaping () -> Void) {
        guard
            !message.isEmpty,
            let conversation = userInfo.conversation(in: managedObjectContext)
            else { return completionHandler() }

        guard let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "DirectReply Action Handler") else {
            return
        }

        applicationStatusDirectory.operationStatus.startBackgroundTask { [weak self] result in
            guard let self else { return }

            self.messageReplyObserver = nil
            self.syncManagedObjectContext.performGroupedBlock {

                let conversationOnSyncContext = userInfo.conversation(in: self.syncManagedObjectContext)
                if result == .failed {
                    Logging.push.safePublic("failed to reply via push notification action")
                    self.localNotificationDispatcher?.didFailToSendMessage(in: conversationOnSyncContext!)
                }

                BackgroundActivityFactory.shared.endBackgroundActivity(activity)
                completionHandler()
            }
        }

        enqueue {
            do {
                let message = try conversation.appendText(content: message)
                self.appendReadReceiptIfNeeded(with: userInfo, in: conversation)
                self.messageReplyObserver = ManagedObjectContextChangeObserver(context: self.managedObjectContext, callback: { [weak self] in
                    self?.updateBackgroundTask(with: message)
                })
            } catch {
                Logging.messageProcessing.warn("Failed to reply to message from user notification. Reason: \(error.localizedDescription)")
            }
        }
    }

    private func appendReadReceiptIfNeeded(with userInfo: NotificationUserInfo, in conversation: ZMConversation) {
        guard
            let originalMessage = userInfo.message(in: conversation, managedObjectContext: self.managedObjectContext) as? ZMClientMessage,
            originalMessage.needsReadConfirmation
        else {
            return
        }

        do {
            let confirmation = GenericMessage(content: Confirmation(messageId: originalMessage.nonce!, type: .read))
            try conversation.appendClientMessage(with: confirmation)
        } catch {
            Logging.messageProcessing.warn("Failed to append read receipt from user notification. Reason: \(error.localizedDescription)")
        }
    }

    public func likeMessage(with userInfo: NotificationUserInfo, completionHandler: @escaping () -> Void) {
        guard
            let conversation = userInfo.conversation(in: managedObjectContext),
            let message = userInfo.message(in: conversation, managedObjectContext: managedObjectContext)
            else { return completionHandler() }

        guard let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "Like Message Activity") else {
            return
        }

        applicationStatusDirectory.operationStatus.startBackgroundTask { [weak self] result in
            guard let self else { return }

            self.likeMesssageObserver = nil
            if result == .failed {
                Logging.push.safePublic("failed to like message via push notification action")
            }
            BackgroundActivityFactory.shared.endBackgroundActivity(activity)
            completionHandler()
        }

        enqueue {
            guard let reaction = ZMMessage.addReaction("❤️", to: message) else { return }
            self.appendReadReceiptIfNeeded(with: userInfo, in: conversation)
            self.likeMesssageObserver = ManagedObjectContextChangeObserver(context: self.managedObjectContext, callback: { [weak self] in
                self?.updateBackgroundTask(with: reaction)
            })
        }
    }

    func updateBackgroundTask(with message: ZMConversationMessage) {
        if message.isSent {
            applicationStatusDirectory.operationStatus.finishBackgroundTask(withTaskResult: .finished)
        } else if message.deliveryState == .failedToSend {
            applicationStatusDirectory.operationStatus.finishBackgroundTask(withTaskResult: .failed)
        }
    }

}

public extension ZMUserSession {
    func markAllConversationsAsRead() {
        let allConversations = managedObjectContext.fetchOrAssert(request: NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName()))
        allConversations.forEach({ $0.markAsRead() })
    }
}
