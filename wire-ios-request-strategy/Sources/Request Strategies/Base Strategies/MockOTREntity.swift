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

// MARK: - MockOTREntity

final class MockOTREntity: OTREntity {
    // MARK: Lifecycle

    init(messageData: Data = Data(), conversation: ZMConversation?, context: NSManagedObjectContext) {
        self.messageData = messageData
        self.conversation = conversation
        self.context = context
    }

    // MARK: Internal

    var context: NSManagedObjectContext
    var expirationDate: Date?
    var shouldExpire = false
    var isExpired = false
    var shouldIgnoreTheSecurityLevelCheck = false
    var expirationReasonCode: NSNumber?

    let messageData: Data

    var conversation: ZMConversation?

    var isMissingClients = false
    var didCallHandleClientUpdates = false
    var isDelivered = false
    var isFailedToSendUsers = false

    var dependentObjectNeedingUpdateBeforeProcessing: NSObject?

    func expire() {
        isExpired = true
    }

    func missesRecipients(_: Set<UserClient>!) {
        // no-op
    }

    func detectedRedundantUsers(_: [ZMUser]) {
        // no-op
    }

    func delivered(with response: ZMTransportResponse) {
        isDelivered = true
    }

    func addFailedToSendRecipients(_: [ZMUser]) {
        isFailedToSendUsers = true
    }
}

// MARK: ProteusMessage

extension MockOTREntity: ProteusMessage {
    var debugInfo: String {
        "Mock ProteusMessage"
    }

    func encryptForTransport() -> EncryptedPayloadGenerator.Payload? {
        (Data("non-qualified".utf8), .doNotIgnoreAnyMissingClient)
    }

    func encryptForTransportQualified() -> EncryptedPayloadGenerator.Payload? {
        (Data("qualified".utf8), .doNotIgnoreAnyMissingClient)
    }

    func setExpirationDate() {
        // no-op
    }
}

func == (lhs: MockOTREntity, rhs: MockOTREntity) -> Bool {
    lhs === rhs
}
