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

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        localNotificationDispatcher: PushMessageHandler,
        applicationStatus: ApplicationStatus,
        messageSender: MessageSenderInterface
    ) {
        insertedObjectSync = InsertedObjectSync(
            insertPredicate: Self.shouldBeSentPredicate(context: context)
        )

        self.context = context
        self.messageSender = messageSender
        self.localNotificationDispatcher = localNotificationDispatcher

        messageExpirationTimer = MessageExpirationTimer(
            moc: context,
            entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()],
            localNotificationDispatcher: localNotificationDispatcher
        )

        linkAttachmentsPreprocessor = LinkAttachmentsPreprocessor(
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
        return [
            insertedObjectSync,
            messageExpirationTimer,
            linkAttachmentsPreprocessor
        ]
    }
}

// MARK: - Inserted object sync transcoder

extension ClientMessageRequestStrategy: InsertedObjectSyncTranscoder {

    typealias Object = ZMClientMessage

    func insert(object: ZMClientMessage, completion: @escaping () -> Void) {
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

                    if case NetworkError.invalidRequestError(let responseFailure, _) = error,
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

// MARK: - Event processing

extension ClientMessageRequestStrategy: ZMEventConsumer {

    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        events.forEach {
            self.insertMessage(from: $0, prefetchResult: prefetchResult)
        }
    }

    public func messageNoncesToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID> {
        return Set(events.compactMap {
            switch $0.type {
            case .conversationClientMessageAdd,
                 .conversationOtrMessageAdd,
                 .conversationOtrAssetAdd,
                 .conversationMLSMessageAdd:
                return $0.messageNonce

            default:
                return nil
            }
        })
    }

    func insertMessage(from event: ZMUpdateEvent, prefetchResult: ZMFetchRequestBatchResult?) {
        switch event.type {
        case .conversationClientMessageAdd, .conversationOtrMessageAdd, .conversationOtrAssetAdd, .conversationMLSMessageAdd:
            guard let message = ZMOTRMessage.createOrUpdate(from: event, in: context, prefetchResult: prefetchResult) else {
                return
            }
            message.markAsSent()

        default:
            break
        }

        context.processPendingChanges()
    }
}

// MARK: - Helpers

private struct UpdateEventWithNonce {

    let event: ZMUpdateEvent
    let nonce: UUID

}
