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

public protocol ProteusMessage: OTREntity, EncryptedPayloadGenerator {

    /// Messages can expire, e.g. if network conditions are too slow to send.
    var shouldExpire: Bool { get }

    /// Sets the expiration date with the default time interval.
    func setExpirationDate()

    func prepareMessageForSending() async throws

    var underlyingMessage: GenericMessage? { get }

    var targetRecipients: Recipients { get }
}

extension ZMClientMessage: ProteusMessage {

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

extension ZMAssetClientMessage: ProteusMessage {

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
