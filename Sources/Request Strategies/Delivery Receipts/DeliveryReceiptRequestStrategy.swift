//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
            let conversation = ZMConversation.fetch(withRemoteIdentifier: conversationID, in: managedObjectContext),
            conversation.conversationType == .oneOnOne,
            let senderUUID = senderUUID,
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
public final class DeliveryReceiptRequestStrategy: AbstractRequestStrategy {
    
    private let genericMessageStrategy: GenericMessageRequestStrategy
    
    // MARK: - Init
    
    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                clientRegistrationDelegate: ClientRegistrationDelegate) {
        
        self.genericMessageStrategy = GenericMessageRequestStrategy(context: managedObjectContext, clientRegistrationDelegate: clientRegistrationDelegate)
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        self.configuration = [.allowsRequestsWhileInBackground,
                              .allowsRequestsWhileOnline,
                              .allowsRequestsWhileWaitingForWebsocket]
    }
    
    // MARK: - Methods
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return genericMessageStrategy.nextRequest()
    }
}

// MARK: - Context Change Tracker

extension DeliveryReceiptRequestStrategy: ZMContextChangeTrackerSource {
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self.genericMessageStrategy]
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
        
    }
    
    public func processEventsWhileInBackground(_ events: [ZMUpdateEvent]) {
        deliveryReceipts(for: events).forEach(sendDeliveryReceipt)
    }
        
    func sendDeliveryReceipt(_ deliveryReceipt: DeliveryReceipt) {
        guard let confirmation = Confirmation.init(messageIds: deliveryReceipt.messageIDs,
                                                   type: .delivered) else { return }
        
        genericMessageStrategy.schedule(message: GenericMessage(content: confirmation),
                                        inConversation: deliveryReceipt.conversation,
                                        targetRecipients: .users(Set(arrayLiteral: deliveryReceipt.sender)),
                                        completionHandler: nil)
        
    }
    
    func deliveryReceipts(for events: [ZMUpdateEvent]) -> [DeliveryReceipt] {
        let eventsByConversation = events.partition(by: \.conversationUUID)

        var deliveryReceipts: [DeliveryReceipt] = []
        
        eventsByConversation.forEach { (conversationID: UUID, events: [ZMUpdateEvent]) in
            guard let conversation = ZMConversation.fetch(withRemoteIdentifier: conversationID,
                                                          in: managedObjectContext) else { return }
            
            let eventsBySender = events
                .filter({ $0.needsDeliveryConfirmation(managedObjectContext: managedObjectContext) })
                .partition(by: \.senderUUID)
            
            eventsBySender.forEach { (senderID: UUID, events: [ZMUpdateEvent]) in
                guard let sender = ZMUser.fetchAndMerge(with: senderID,
                                                        createIfNeeded: true,
                                                        in: managedObjectContext) else { return }
                
                let deliveryReceipt = DeliveryReceipt(sender: sender,
                                                      conversation: conversation,
                                                      messageIDs: events.compactMap(\.messageNonce))
                deliveryReceipts.append(deliveryReceipt)
            }
        }
        
        return deliveryReceipts
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
