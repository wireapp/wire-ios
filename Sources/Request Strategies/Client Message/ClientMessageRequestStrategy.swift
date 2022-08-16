//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public class ClientMessageRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    static func shouldBeSentPredicate(context: NSManagedObjectContext) -> NSPredicate {
        let notDelivered = NSPredicate(format: "%K == FALSE", DeliveredKey)
        let notExpired = NSPredicate(format: "%K == 0", ZMMessageIsExpiredKey)
        let fromSelf = NSPredicate(format: "%K == %@", ZMMessageSenderKey, ZMUser.selfUser(in: context))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notDelivered, notExpired, fromSelf])
    }

    // MARK: - Properties

    let insertedObjectSync: InsertedObjectSync<ClientMessageRequestStrategy>
    let messageSync: MessageSync<ZMClientMessage>
    let messageExpirationTimer: MessageExpirationTimer
    let linkAttachmentsPreprocessor: LinkAttachmentsPreprocessor
    let localNotificationDispatcher: PushMessageHandler

    // MARK: - Life cycle

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        localNotificationDispatcher: PushMessageHandler,
        applicationStatus: ApplicationStatus
    ) {
        insertedObjectSync = InsertedObjectSync(
            insertPredicate: Self.shouldBeSentPredicate(context: managedObjectContext)
        )

        messageSync = MessageSync(
            context: managedObjectContext,
            appStatus: applicationStatus
        )

        self.localNotificationDispatcher = localNotificationDispatcher

        messageExpirationTimer = MessageExpirationTimer(
            moc: managedObjectContext,
            entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()],
            localNotificationDispatcher: localNotificationDispatcher
        )

        linkAttachmentsPreprocessor = LinkAttachmentsPreprocessor(
            linkAttachmentDetector: LinkAttachmentDetectorHelper.defaultDetector(),
            managedObjectContext: managedObjectContext
        )

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsWhileInBackground
        ]

        insertedObjectSync.transcoder = self

        messageSync.onRequestScheduled { [weak self] message, _ in
            self?.messageExpirationTimer.stop(for: message)
        }
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
        ] + messageSync.contextChangeTrackers
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return messageSync.nextRequest(for: apiVersion)
    }

}

// MARK: - Inserted object sync transcoder

extension ClientMessageRequestStrategy: InsertedObjectSyncTranscoder {

    typealias Object = ZMClientMessage

    func insert(object: ZMClientMessage, completion: @escaping () -> Void) {
        messageSync.sync(object) { [weak self] result, response in
            switch result {
            case .success:
                object.markAsSent()
                self?.deleteMessageIfNecessary(object)

            case .failure(let error):
                switch error {
                case .messageProtocolMissing:
                    object.expire()
                    self?.localNotificationDispatcher.didFailToSend(object)

                case .expired, .gaveUpRetrying:
                    object.expire()
                    self?.localNotificationDispatcher.didFailToSend(object)

                    let payload = Payload.ResponseFailure(response, decoder: .defaultDecoder)
                    if response.httpStatus == 403 && payload?.label == .missingLegalholdConsent {
                        self?.managedObjectContext.zm_userInterface.performGroupedBlock {
                            guard let context = self?.managedObjectContext.notificationContext else { return }
                            NotificationInContext(name: ZMConversation.failedToSendMessageNotificationName, context: context).post()
                        }
                    }
                }
            }

            completion()
        }
    }

    private func deleteMessageIfNecessary(_ message: ZMClientMessage) {
        guard let underlyingMessage = message.underlyingMessage else { return }

        if underlyingMessage.hasReaction {
            managedObjectContext.delete(message)
        }

        if underlyingMessage.hasConfirmation {
            // NOTE: this will only be read confirmations since delivery confirmations
            // are not sent using the ClientMessageTranscoder
            managedObjectContext.delete(message)
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
            guard let message = ZMOTRMessage.createOrUpdate(from: event, in: managedObjectContext, prefetchResult: prefetchResult) else { return }
            message.markAsSent()

        default:
            break
        }

        managedObjectContext.processPendingChanges()
    }
}

// MARK: - Helpers

private struct UpdateEventWithNonce {

    let event: ZMUpdateEvent
    let nonce: UUID

}
