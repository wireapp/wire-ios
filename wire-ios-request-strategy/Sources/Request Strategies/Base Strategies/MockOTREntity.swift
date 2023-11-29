//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireRequestStrategy
import XCTest

@objcMembers class MockOTREntity: OTREntity, Hashable {

    var context: NSManagedObjectContext
    public var expirationDate: Date?
    public var isExpired: Bool = false
    public func expire() {
        isExpired = true
    }
    public var expirationReasonCode: NSNumber?

    let messageData: Data

    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // no-op
    }
    public var conversation: ZMConversation?

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

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.conversation!)
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
    var debugInfo: String {
        "Mock ProteusMessage"
    }

    func encryptForTransport() -> EncryptedPayloadGenerator.Payload? {
        return ("non-qualified".data(using: .utf8)!, .doNotIgnoreAnyMissingClient)
    }

    func encryptForTransportQualified() -> EncryptedPayloadGenerator.Payload? {
        return ("qualified".data(using: .utf8)!, .doNotIgnoreAnyMissingClient)
    }

}

func == (lhs: MockOTREntity, rhs: MockOTREntity) -> Bool {
    return lhs === rhs
}
