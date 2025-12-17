//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import GenericMessageProtocol
import WireLogging

extension ZMUpdateEvent {

    private static let deliveryConfirmationDayThreshold = 7

    func needsDeliveryConfirmation(
        _ currentDate: Date = Date(),
        managedObjectContext: NSManagedObjectContext
    ) -> Bool {

        guard
            let message = GenericMessage(from: self, validate: true),
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
// TODO: remove full request strategy
@objcMembers
public final class DeliveryReceiptRequestStrategy: NSObject {

    private let messageSender: MessageSenderInterface
    private let managedObjectContext: NSManagedObjectContext

    // MARK: - Init

    public init(
        managedObjectContext: NSManagedObjectContext,
        messageSender: MessageSenderInterface
    ) {

        self.managedObjectContext = managedObjectContext
        self.messageSender = messageSender
    }
}


private extension GenericMessage {

    var needsDeliveryConfirmation: Bool {
        switch content {
        case .text, .image, .asset, .knock, .external, .location, .ephemeral, .composite:
            true
        default:
            false
        }
    }

}
