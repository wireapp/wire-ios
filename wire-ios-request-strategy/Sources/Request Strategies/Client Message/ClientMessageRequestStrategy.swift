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
import WireTransport
import WireUtilities

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
    let reachability: any ReachabilityProvider

    /// Attempts that fail with a transient error while the network seems reachable. Waiting while
    /// offline doesn't count.
    private let maxOnlineRetries = 3

    /// Delay before retrying an attempt that was cancelled, e.g. because the app is in the background.
    private let cancelledRetryDelay = 10

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        localNotificationDispatcher: PushMessageHandler,
        messageSender: MessageSenderInterface,
        reachability: any ReachabilityProvider
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
    }

    deinit {
        self.messageExpirationTimer.tearDown()
    }

    // MARK: - Methods

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [
            insertedObjectSync,
            messageExpirationTimer,
            linkAttachmentsPreprocessor
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

        let staysPendingWhileOffline = object.staysPendingWhileOffline
        if !isFresh, !staysPendingWhileOffline {
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
            var heldGroups = groups
            defer {
                context.leaveAllGroups(heldGroups)
            }
            do {
                try await send(object, staysPendingWhileOffline: staysPendingWhileOffline, groups: &heldGroups)

                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.debug("successfully sent message", attributes: logAttributes)

                await context.perform {
                    object.markAsSent()
                    self.deleteMessageIfNecessary(object)
                }
            } catch PendingMessageError.noLongerNeeded {
                let logAttributes = await logAttributesBuilder.logAttributes(object)
                WireLogger.messaging.info("pending message no longer needs to be sent", attributes: logAttributes)
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

    // MARK: - Pending messages

    private enum PendingMessageError: Error {
        /// The message was deleted, expired or otherwise changed while it was waiting.
        case noLongerNeeded
    }

    /// Sends the message. If it stays pending while offline, transient network failures don't fail it:
    /// it waits until the network may be reachable again and is resent with the same nonce and content.
    ///
    /// - Parameter groups: The context's groups held for this send. They're released while waiting.
    private func send(
        _ message: ZMClientMessage,
        staysPendingWhileOffline: Bool,
        groups: inout [ZMSDispatchGroup]
    ) async throws {
        guard staysPendingWhileOffline else {
            try await messageSender.sendMessage(message: message)
            return
        }

        var onlineRetries = 0
        while true {
            if !reachability.mayBeReachable {
                await waitWithoutHoldingGroups(&groups) {
                    await self.reachability.waitUntilMayBeReachable()
                }
            }

            let shouldStillBeSent = await context.perform {
                guard
                    !message.isZombieObject,
                    message.underlyingMessage != nil,
                    Self.shouldBeSentPredicate(context: self.context).evaluate(with: message)
                else {
                    return false
                }

                // From now on the text may reach recipients, so it must no longer be replaced in place.
                // Both happen on this context, so an in-place edit can't interleave with the send.
                if !message.sendAttemptStarted {
                    message.sendAttemptStarted = true
                    self.context.saveOrRollback()
                }
                return true
            }
            guard shouldStillBeSent else { throw PendingMessageError.noLongerNeeded }

            do {
                try await messageSender.sendMessage(message: message)
                return
            } catch {
                let isOffline = !reachability.mayBeReachable
                // The background task ran out of time, e.g. because the app went to the background.
                let isCancelled = error is CancellationError
                guard
                    isOffline || isCancelled || (Self.isTransientFailure(error) && onlineRetries < maxOnlineRetries)
                else {
                    throw error
                }

                let logAttributes = await MessageLogAttributesBuilder(context: context).logAttributes(message)
                WireLogger.messaging.info(
                    "keeping message pending after transient failure: \(error)",
                    attributes: logAttributes
                )

                // The attempt armed the expiration timer, which must not fire while the message waits.
                await context.perform {
                    self.messageExpirationTimer.stop(for: message)
                    message.removeExpirationDate()
                }

                if isCancelled {
                    await waitWithoutHoldingGroups(&groups) {
                        try? await Task.sleep(for: .seconds(self.cancelledRetryDelay))
                    }
                } else if !isOffline {
                    onlineRetries += 1
                    let delay = 1 << onlineRetries
                    await waitWithoutHoldingGroups(&groups) {
                        try? await Task.sleep(for: .seconds(delay))
                    }
                }
            }
        }
    }

    /// Runs `wait` without holding the context's groups, since tearing down the session waits until they're
    /// empty and a pending message can wait for a long time.
    private func waitWithoutHoldingGroups(
        _ groups: inout [ZMSDispatchGroup],
        _ wait: () async -> Void
    ) async {
        context.leaveAllGroups(groups)
        await wait()
        groups = context.enterAllGroupsExceptSecondary()
    }

    private static func isTransientFailure(_ error: any Error) -> Bool {
        let networkError: NetworkError? = switch error {
        case let error as NetworkError:
            error
        case let MessageSendError.failed(error as NetworkError):
            error
        default:
            nil
        }
        return networkError?.response?.result == .tryAgainLater
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

// MARK: - Reachability

private extension ReachabilityProvider {

    /// Returns once the network may be reachable, immediately if it already is.
    func waitUntilMayBeReachable() async {
        guard !mayBeReachable else { return }

        var token: Any?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let lock = NSLock()
            var resumed = false
            let resumeOnce = {
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                continuation.resume()
            }

            token = addReachabilityObserver(on: nil) { provider in
                if provider.mayBeReachable {
                    resumeOnce()
                }
            }

            // Reachability may have changed before the observer was registered.
            if mayBeReachable {
                resumeOnce()
            }
        }
        withExtendedLifetime(token) {}
    }
}
