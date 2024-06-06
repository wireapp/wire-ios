//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

/// A message that can be sent in an mls group.

public protocol MLSMessage: OTREntity, MLSEncryptedPayloadGenerator, Hashable {
    var logInformation: LogAttributes { get }
}

extension ZMClientMessage: MLSMessage {
    
}

extension ZMAssetClientMessage: MLSMessage {
    public var logInformation: LogAttributes {

        return [
            LogAttributesKey.nonce.rawValue: self.nonce?.safeForLoggingDescription ?? "<nil>",
            LogAttributesKey.messageType.rawValue: self.underlyingMessage?.safeTypeForLoggingDescription ?? "<nil>",
            LogAttributesKey.conversationId.rawValue: self.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ].merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })

    }
}

extension GenericMessageEntity: MLSMessage {

    public func encryptForTransport(using encrypt: (Data) async throws -> Data) async throws -> Data {
        return try await message.encryptForTransport(using: encrypt)
    }

    public var logInformation: LogAttributes {

        let logAttibutes: LogAttributes = [
            LogAttributesKey.nonce.rawValue: self.message.messageID.lowercased().redactedAndTruncated(maxVisibleCharacters: 7, length: 10),
            LogAttributesKey.messageType.rawValue: self.message.safeTypeForLoggingDescription,
            LogAttributesKey.conversationId.rawValue: self.conversation?.qualifiedID?.safeForLoggingDescription ?? "<nil>"
        ].merging(LogAttributes.safePublic, uniquingKeysWith: { _, new in new })

        return logAttibutes
    }
}
