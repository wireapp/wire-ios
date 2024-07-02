//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public protocol ProteusMessage: OTREntity, EncryptedPayloadGenerator, Hashable {
    var logInformation: LogAttributes { get }

    /// Sets the expiration date with the default time interval and returns the date.
    func setExpirationDate()
}

extension ZMClientMessage: ProteusMessage {

    public var logInformation: LogAttributes {

        return [
            LogAttributesKey.nonce.rawValue: self.nonce?.safeForLoggingDescription ?? "<nil>",
            LogAttributesKey.messageType.rawValue: self.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
            LogAttributesKey.conversationId.rawValue: self.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ].merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })

    }
}

extension ZMAssetClientMessage: ProteusMessage {}
