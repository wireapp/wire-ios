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

import WireDataModel
import XCTest

@testable import WireRequestStrategy

final class MockOTREntity: OTREntity {

    var context: NSManagedObjectContext
    var expirationDate: Date?
    var shouldExpire: Bool = false
    var isExpired: Bool = false
    var shouldIgnoreTheSecurityLevelCheck: Bool = false
    func expire() {
        isExpired = true
    }
    var expirationReasonCode: NSNumber?

    let messageData: Data

    func missesRecipients(_ recipients: Set<UserClient>!) {
        // no-op
    }
    var conversation: ZMConversation?

    var isMissingClients = false
    var didCallHandleClientUpdates = false
    var isDelivered = false
    var isFailedToSendUsers = false

    var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    init(messageData: Data = Data(), conversation: ZMConversation?, context: NSManagedObjectContext) {
        self.messageData = messageData
        self.conversation = conversation
        self.context = context
    }

    func detectedRedundantUsers(_ users: [ZMUser]) {
        // no-op
    }

    func delivered(with response: ZMTransportResponse) {
        isDelivered = true
    }

    func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        isFailedToSendUsers = true
    }

}

extension MockOTREntity: ProteusMessage {
    var targetRecipients: WireRequestStrategy.Recipients {
        .conversationParticipants
    }

    func prepareMessageForSending() async throws {

    }

    var debugInfo: String {
        "Mock ProteusMessage"
    }

    var underlyingMessage: GenericMessage? {
        return nil
    }

    func setExpirationDate() {
        // no-op
    }
}

func == (lhs: MockOTREntity, rhs: MockOTREntity) -> Bool {
    return lhs === rhs
}
