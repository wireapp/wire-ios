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

import Foundation
import WireLogging
import WireSystem
import WireTransport

public class ClientMessageRequestStrategy: NSObject, ZMContextChangeTrackerSource {

    static func shouldBeSentPredicate(context: NSManagedObjectContext) -> NSPredicate {
        let notDelivered = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        let fromSelf = NSPredicate(format: "%K == %@", ZMMessageSenderKey, ZMUser.selfUser(in: context))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notDelivered, notExpired, fromSelf])
    }

    // MARK: - Properties

    let context: NSManagedObjectContext
    let insertedObjectSync: InsertedObjectSync<ClientMessageRequestStrategy>
    let messageSender: MessageSenderInterface
    let messageExpirationTimer: MessageExpirationTimer
    let linkAttachmentsPreprocessor: LinkAttachmentsPreprocessor
    let localNotificationDispatcher: PushMessageHandler
    private let reachability: ReachabilityProvider?
    private var reachabilityToken: Any?
    private var queuedOutboxMessages: [NSManagedObjectID: (message: ZMClientMessage, completion: () -> Void)] = [:]
    private var outboxTasks: [NSManagedObjectID: Task<Void, Never>] = [:]
    private var activeOutboxConversations = Set<NSManagedObjectID>()
    private var outboxRetryWakeup: DispatchWorkItem?
    private var isTornDown = false

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        localNotificationDispatcher: PushMessageHandler,
        messageSender: MessageSenderInterface,
        reachability: ReachabilityProvider? = nil
    ) {
        self.insertedObjectSync = InsertedObjectSync(
            insertPredicate: Self.shouldBeSentPredicate(context: context)
        )

        self.context = context
        self.messageSender = messageSender
        self.localNotificationDispatcher = localNotificationDispatcher
        self.reachability = reachability

        self.messageExpirationTimer = MessageExpirationTimer(
            moc: context,
            entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()],
            localNotificationDispatcher: localNotificationDispatcher
        )

        self.linkAttachmentsPreprocessor = LinkAttachmentsPreprocessor(
            linkAttachmentDetector: LinkAttachmentDetectorHelper.defaultDetector(),
            managedObjectContext: context
        )

        super.init()

        insertedObjectSync.transcoder = self
        reachabilityToken = reachability?.addReachabilityObserver(on: nil) { [weak self] _ in
            self?.context.performGroupedBlock { [weak self] in
                self?.drainOutbox()
            }
        }
    }

    deinit {
        self.messageExpirationTimer.tearDown()
    }

    // MARK: - Methods

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [
            insertedObjectSync,
            messageExpirationTimer,
            linkAttachmentsPreprocessor,
            self
        ]
    }
}

// MARK: - Inserted object sync transcoder

extension ClientMessageRequestStrategy: InsertedObjectSyncTranscoder {

    typealias Object = ZMClientMessage

    func insert(
        object: ZMClientMessage,
        isFresh: Bool,
        completion: @escaping () -> Void
    ) {
        if object.outboxState != .notEnrolled {
            enqueueOutboxMessage(object, isFresh: isFresh, completion: completion)
            return
        }
        // Temp fix for avoiding to send a large amount of last read
        // messages, see: [WPB-17439]
        if
            let conversation = object.conversation,
            conversation.isSelfConversation,
            conversation.messageProtocol == .mls {
            completion()
            return
        }

        let hasRegisteredMLSClient = context.performAndWait {
            let selfClient = ZMUser.selfUser(in: context).selfClient()
            return selfClient?.hasRegisteredMLSClient ?? false
        }

        if !hasRegisteredMLSClient, object.conversation?.messageProtocol == .mls {
            completion()
            return
        }

        if !isFresh {
            // This message was not added in this runtime. Rather than send it
            // which may no longer make sense after such as delay, we will
            // expire it so the user can retry.
            WireLogger.messaging.info(
                "expiring stale client message",
                attributes: [.nonce: object.nonce?.safeForLoggingDescription ?? "<nil>"],
                .safePublic
            )
            object.expire(withReason: .timeout)
            context.saveOrRollback()
            completion()
            return
        }
        let logAttributesBuilder = MessageLogAttributesBuilder(context: context)
        let logAttributes = logAttributesBuilder.syncLogAttributes(object)
        WireLogger.messaging.debug("inserting message", attributes: logAttributes)

        // Enter groups to enable waiting for message sending to complete in tests
        let groups = context.enterAllGroupsExceptSecondary()
        Task {
            defer {
                context.leaveAllGroups(groups)
            }
            do {
                try await messageSender.sendMessage(message: object)

                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.debug("successfully sent message", attributes: logAttributes)

                await context.perform {
                    object.markAsSent()
                    self.deleteMessageIfNecessary(object)
                }
            } catch {
                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.error("failed to send message: \(error)", attributes: logAttributes)
                await context.perform {
                    object.expire(withReason: .other)
                    self.localNotificationDispatcher.didFailToSend(object)

                    if case let NetworkError.invalidRequestError(responseFailure, _) = error,
                       responseFailure.label == .missingLegalholdConsent {
                        self.context.zm_userInterface.performGroupedBlock {
                            NotificationInContext(
                                name: ZMConversation.failedToSendMessageNotificationName,
                                context: self.context.notificationContext
                            ).post()
                        }
                    }
                }
            }

            await context.perform {
                self.messageExpirationTimer.stop(for: object)
                self.context.enqueueDelayedSave()
                // make sure completion is called on same calling thread so syncContext
                completion()
            }
        }
    }

    private func deleteMessageIfNecessary(_ message: ZMClientMessage) {
        guard let underlyingMessage = message.underlyingMessage else { return }

        if underlyingMessage.hasReaction {
            WireLogger.messaging.debug("deleting message: \(message.debugInfo)")
            context.delete(message)
        }

        if underlyingMessage.hasConfirmation {
            // NOTE: this will only be read confirmations since delivery confirmations
            // are not sent using the ClientMessageTranscoder
            WireLogger.messaging.debug("deleting message: \(message.debugInfo)")
            context.delete(message)
        }
    }

}

extension ClientMessageRequestStrategy: ZMContextChangeTracker, TearDownCapable {

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? { nil }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        drainOutbox()
    }

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        drainOutbox()
    }

    public func tearDown() {
        context.performAndWait {
            isTornDown = true
            reachabilityToken = nil
            outboxRetryWakeup?.cancel()
            outboxRetryWakeup = nil
            outboxTasks.values.forEach { $0.cancel() }
            outboxTasks.removeAll()
            let pending = queuedOutboxMessages.values.map { $0.completion }
            queuedOutboxMessages.removeAll()
            activeOutboxConversations.removeAll()
            pending.forEach { $0() }
            messageExpirationTimer.tearDown()
        }
    }
}

private extension ClientMessageRequestStrategy {

    func enqueueOutboxMessage(_ message: ZMClientMessage, isFresh: Bool, completion: @escaping () -> Void) {
        guard !isTornDown, !message.isDeleted, !message.hasBeenDeleted else {
            completion()
            return
        }
        if !isFresh {
            message.recoverOutboxAfterRestart()
        }
        if message.outboxState == .uncertain {
            // Surface existing Retry until automatic reconciliation of unknown delivery is agreed.
            message.expire(withReason: .other)
        }
        do {
            try context.save()
        } catch {
            WireLogger.messaging.error("could not persist recovered outbox message")
            completion()
            return
        }
        guard message.outboxState == .queued, !message.isExpired else {
            completion()
            return
        }
        queuedOutboxMessages[message.objectID] = (message, completion)
        drainOutbox()
    }

    func drainOutbox() {
        guard !isTornDown, reachability?.mayBeReachable != false else { return }
        outboxRetryWakeup?.cancel()
        outboxRetryWakeup = nil
        var blockedConversations = activeOutboxConversations
        var nextWakeup: Date?
        let waiting = queuedOutboxMessages.values.sorted {
            ($0.message.outboxEnqueuedAt ?? .distantPast) < ($1.message.outboxEnqueuedAt ?? .distantPast)
        }
        for entry in waiting {
            let message = entry.message
            guard outboxTasks[message.objectID] == nil else { continue }
            guard !message.isDeleted, !message.hasBeenDeleted, !message.isExpired,
                  message.outboxState == .queued, let conversation = message.conversation
            else {
                queuedOutboxMessages.removeValue(forKey: message.objectID)?.completion()
                continue
            }
            let conversationID = conversation.objectID
            guard !blockedConversations.contains(conversationID) else { continue }
            blockedConversations.insert(conversationID)
            if conversation.messageProtocol == .mls,
               ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient != true {
                continue
            }
            if let date = message.outboxNextAttemptAt, date > Date() {
                nextWakeup = min(nextWakeup ?? date, date)
                continue
            }
            activeOutboxConversations.insert(conversationID)
            let objectID = message.objectID
            outboxTasks[objectID] = Task { [self] in
                let waitsForConnection: Bool
                do {
                    try await messageSender.sendMessage(message: message)
                    waitsForConnection = false
                } catch MessageSendError.outboxWaitingForConnection {
                    waitsForConnection = true
                } catch MessageOutboxError.staleAttempt {
                    // An obsolete operation must not expire its replacement or a cancelled message.
                    waitsForConnection = false
                } catch {
                    await context.perform {
                        guard !self.isTornDown, !message.isDeleted, !message.hasBeenDeleted,
                              message.outboxState != .cancelled, message.outboxState != .sent
                        else { return }
                        if message.outboxState == .queued {
                            try? message.failQueuedOutboxOperation()
                        }
                        message.expire(withReason: .other)
                        self.localNotificationDispatcher.didFailToSend(message)
                        if case let NetworkError.invalidRequestError(failure, _) = error,
                           failure.label == .missingLegalholdConsent {
                            self.context.zm_userInterface.performGroupedBlock {
                                NotificationInContext(
                                    name: ZMConversation.failedToSendMessageNotificationName,
                                    context: self.context.notificationContext
                                ).post()
                            }
                        }
                    }
                    waitsForConnection = false
                }
                await context.perform {
                    guard !self.isTornDown else { return }
                    self.outboxTasks.removeValue(forKey: objectID)
                    self.activeOutboxConversations.remove(conversationID)
                    if !waitsForConnection, message.outboxState != .queued {
                        self.queuedOutboxMessages.removeValue(forKey: objectID)?.completion()
                    }
                    self.context.enqueueDelayedSave()
                    self.drainOutbox()
                }
            }
        }
        if let nextWakeup {
            let work = DispatchWorkItem { [weak self] in
                self?.context.performGroupedBlock { [weak self] in self?.drainOutbox() }
            }
            outboxRetryWakeup = work
            DispatchQueue.global(qos: .utility).asyncAfter(
                deadline: .now() + max(0, nextWakeup.timeIntervalSinceNow),
                execute: work
            )
        }
    }
}
