//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireNetwork

struct ProtobufMessageDecoder {
    
    // MARK: - Error types

    enum Failure: Error {
        case failedToDecodeGenericMessage
        case unknownMessageContent
        case failedToDecodeExternalProteusData
        case failedToDecryptExternalProteusData
        case externalProteusDataSHAMismatch
        case externalProteusDataMissing
    }
    
    // MARK: - Interface
    
    func extractMLSMessageContent(
        from base64Message: String
    ) throws -> GenericMessage {
        try extractMessageContent(from: base64Message)
    }
    
    func extractProteusMessageContent(
        from base64Message: String,
        externalData: MessageContent?
    ) throws -> GenericMessage {
        var message = try extractMessageContent(from: base64Message)

        // Extra large proteus messages (many recipients) are contained
        // in external data.
        if case let .external(externalMessage) = message.content {
            guard let externalData = externalData?.encryptedMessage else {
                throw Failure.externalProteusDataMissing
            }

            message = try decryptExternalProteusData(
                external: externalMessage,
                externalData: externalData
            )
        }
        
        return message
    }
    
    // MARK: - Private methods
    
    private func extractMessageContent(from base64Message: String) throws -> GenericMessage {
        // Decode the protobuf message.
        guard let genericMessage = GenericMessage(
            from: base64Message,
            validate: true
        ) else {
            throw Failure.failedToDecodeGenericMessage
        }

        // Ensure the content is understood.
        if genericMessage.content == nil {
            throw Failure.unknownMessageContent
        }

        return genericMessage
    }

    private func decryptExternalProteusData(
        external: External,
        externalData: String
    ) throws -> GenericMessage {
        // Decode the base64 external data.
        guard let encryptedData = Data(base64Encoded: externalData) else {
            throw Failure.failedToDecodeExternalProteusData
        }

        // Verify SHA256 hash.
        guard encryptedData.zmSHA256Digest() == external.sha256 else {
            throw Failure.externalProteusDataSHAMismatch
        }

        // Decrypt the data.
        guard let decryptedData = encryptedData.zmDecryptPrefixedPlainTextIV(
            key: external.otrKey
        ) else {
            throw Failure.failedToDecryptExternalProteusData
        }

        // Decode the decrypted message.
        guard let message = GenericMessage(
            from: decryptedData.base64String(),
            validate: true
        ) else {
            throw Failure.failedToDecryptExternalProteusData
        }

        return message
    }
}
