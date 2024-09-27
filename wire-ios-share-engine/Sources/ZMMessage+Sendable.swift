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
import WireDataModel

extension ZMMessage {
    private var reportsProgress: Bool {
        fileMessageData != nil || imageMessageData != nil
    }
}

// MARK: - ZMMessage + Sendable

extension ZMMessage: Sendable {
    public var blockedBecauseOfMissingClients: Bool {
        guard let message = self as? ZMOTRMessage else {
            return false
        }
        return deliveryState == .failedToSend && message.causedSecurityLevelDegradation
    }

    public var isSent: Bool {
        if let clientMessage = self as? ZMClientMessage {
            if clientMessage.linkPreviewState != .done {
                return false
            }
        }

        return delivered
    }

    public var deliveryProgress: Float? {
        if let asset = self as? ZMAssetClientMessage, reportsProgress {
            return asset.progress
        }

        return nil
    }

    public func cancel() {
        if let asset = fileMessageData {
            asset.cancelTransfer()
            return
        }

        let attributes: LogAttributes = [.nonce: nonce?.safeForLoggingDescription ?? "<nil>"]
            .merging(.safePublic, uniquingKeysWith: { _, new in new })

        WireLogger.messaging.warn("expiring message because of cancel", attributes: attributes)
        expire()
    }
}
