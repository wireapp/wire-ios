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

extension ZMUpdateEvent {

    private static let deliveryConfirmationDayThreshold = 7

    func needsDeliveryConfirmation(_ currentDate: Date = Date(),
                                   managedObjectContext: NSManagedObjectContext) -> Bool {

        guard
            let message = GenericMessage(from: self),
            message.needsDeliveryConfirmation,
            let conversationID = conversationUUID,
            let conversation = ZMConversation.fetch(with: conversationID, in: managedObjectContext),
            conversation.conversationType == .oneOnOne,
            let senderUUID,
            senderUUID != ZMUser.selfUser(in: managedObjectContext).remoteIdentifier,
            let serverTimestamp = timestamp,
            let daysElapsed = Calendar.current.dateComponents([.day], from: serverTimestamp, to: currentDate).day
        else {
            return false
        }

        return daysElapsed <= ZMUpdateEvent.deliveryConfirmationDayThreshold
    }
}

@objcMembers
public final class DeliveryReceiptRequestStrategy: NSObject {

    private let messageSender: MessageSenderInterface
    private let managedObjectContext: NSManagedObjectContext

    // MARK: - Init

    public init(managedObjectContext: NSManagedObjectContext,
                messageSender: MessageSenderInterface) {

        self.managedObjectContext = managedObjectContext
        self.messageSender = messageSender
    }
}

// MARK: - Event Consumer

extension DeliveryReceiptRequestStrategy: ZMEventConsumer {

    struct DeliveryReceipt {
        let sender: ZMUser
        let conversation: ZMConversation
        let messageIDs: [UUID]
    }

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        deliveryReceipts(for: events).forEach(sendDeliveryReceipt)
    }

    func sendDeliveryReceipt(_ deliveryReceipt: DeliveryReceipt) {
        guard let confirmation = Confirmation.init(messageIds: deliveryReceipt.messageIDs,
                                                   type: .delivered) else { return }
        let senderUserSet: Set<ZMUser> = [deliveryReceipt.sender]

        WaitingGroupTask(context: managedObjectContext) { [self] in
            do {
                try await messageSender.sendMessage(message: GenericMessageEntity(message: GenericMessage(content: confirmation),
                                                                                  context: managedObjectContext,
                                                                                  conversation: deliveryReceipt.conversation,
                                                                                  targetRecipients: .users(senderUserSet),
                                                                                  completionHandler: nil))
            } catch {
                WireLogger.messaging.error("send delivery receipt: \(error.localizedDescription)")
            }
        }
    }

    func deliveryReceipts(for events: [ZMUpdateEvent]) -> [DeliveryReceipt] {
        let eventsByConversation = events.partition(by: \.conversationUUID)

        var deliveryReceipts: [DeliveryReceipt] = []

        eventsByConversation.forEach { (conversationID: UUID, events: [ZMUpdateEvent]) in
            guard let conversation = ZMConversation.fetch(with: conversationID,
                                                          in: managedObjectContext) else { return }

            let eventsBySender = events
                .filter({ $0.needsDeliveryConfirmation(managedObjectContext: managedObjectContext) })
                .partition(by: \.senderUUID)

            eventsBySender.forEach { (senderID: UUID, events: [ZMUpdateEvent]) in

                let eventsByDomain = events.partition(by: \.senderDomain)
                let eventsWithoutDomain = events.filter({ $0.senderDomain == nil })

                eventsByDomain.forEach { (domain: String, events: [ZMUpdateEvent]) in
                    deliveryReceipts.append(deliveryReceipt(for: senderID,
                                                            domain: domain,
                                                            conversation: conversation,
                                                            events: events))
                }

                if !eventsWithoutDomain.isEmpty {
                    deliveryReceipts.append(deliveryReceipt(for: senderID,
                                                            domain: nil,
                                                            conversation: conversation,
                                                            events: events))
                }
            }
        }

        return deliveryReceipts
    }

    private func deliveryReceipt(for senderID: UUID,
                                 domain: String?,
                                 conversation: ZMConversation,
                                 events: [ZMUpdateEvent]) -> DeliveryReceipt {
        let sender = ZMUser.fetchOrCreate(with: senderID,
                                          domain: domain,
                                          in: managedObjectContext)
        return DeliveryReceipt(sender: sender,
                               conversation: conversation,
                               messageIDs: events.compactMap(\.messageNonce))
    }

}

private extension GenericMessage {

    var needsDeliveryConfirmation: Bool {
        switch content {
        case .text, .image, .asset, .knock, .external, .location, .ephemeral, .composite:
            return true
        default:
            return false
        }
    }

}
