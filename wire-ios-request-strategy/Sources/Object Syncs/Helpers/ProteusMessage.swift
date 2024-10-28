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
// sourcery: AutoMockable
public protocol ProteusMessage: OTREntity {

    /// Messages can expire, e.g. if network conditions are too slow to send.
    var shouldExpire: Bool { get }

    /// Sets the expiration date with the default time interval.
    func setExpirationDate()

    func prepareMessageForSending() async throws

    var underlyingMessage: GenericMessage? { get }

    var targetRecipients: Recipients { get }

    func setUnderlyingMessage(_ message: GenericMessage) throws
}

extension ProteusMessage {

    public var debugInfo: String {
        guard let message = underlyingMessage else {
            return "\(self)"
        }

        if case .confirmation = message.content {
            return "Confirmation Message"
        } else if case .calling? = message.content {
            return "Calling Message"
        } else if case .clientAction? = message.content {
            switch message.clientAction {
            case .resetSession: return "Reset Session Message"
            }
        }
        return "\(String(describing: message))"
    }
}

extension ZMClientMessage: ProteusMessage {}
extension ZMAssetClientMessage: ProteusMessage {}

extension ProteusMessage where Self: ZMOTRMessage {

    public var targetRecipients: Recipients {
        .conversationParticipants
    }

    public func prepareMessageForSending() async throws {
        try await context.perform { [self] in
            if conversation?.conversationType == .oneOnOne {
                // Update expectsReadReceipt flag to reflect the current user setting
                if var updatedGenericMessage = underlyingMessage {
                    updatedGenericMessage.setExpectsReadConfirmation(ZMUser.selfUser(in: context).readReceiptsEnabled)
                    try setUnderlyingMessage(updatedGenericMessage)
                }
            }

            if let legalHoldStatus = conversation?.legalHoldStatus {
                // Update the legalHoldStatus flag to reflect the current known legal hold status
                if var updatedGenericMessage = underlyingMessage {
                    updatedGenericMessage.setLegalHoldStatus(legalHoldStatus.denotesEnabledComplianceDevice ? .enabled : .disabled)
                    try setUnderlyingMessage(updatedGenericMessage)
                }
            }

        }
    }
}
