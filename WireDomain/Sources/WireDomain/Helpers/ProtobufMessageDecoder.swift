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

struct ProtobufMessageDecoder {

    private init() {}

    static func getProtobufMessage(
        from base64Message: String,
        externalData: String? = nil
    ) -> (GenericMessage, GenericMessage.OneOf_Content)? {
        var genericMessage = GenericMessage(from: base64Message, validate: true)

        // If the encrypted payload is bigger than a certain size, an External Message is sent instead of a regular
        // message.
        // See `External` section from https://github.com/wireapp/generic-message-proto
        // See `External messages` section from
        // https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/20545866/Messages
        if let externalData,
           case let .some(.external(external)) = genericMessage?.content {

            // Content message is external, we decrypt the external payload
            // and turns it back into a generic non-external content message.
            if let decryptedGenericMessage = decryptExternalMessage(
                externalData: externalData,
                external: external
            ) {
                genericMessage = decryptedGenericMessage
            } else {
                return nil
            }
        }

        guard let genericMessage, let content = genericMessage.content else {
            return nil
        }

        return (genericMessage, content)
    }

    private static func decryptExternalMessage(
        externalData: String,
        external: External
    ) -> GenericMessage? {
        let externalData = Data(base64Encoded: externalData)
        let externalSha256 = externalData?.zmSHA256Digest()

        guard externalSha256 == external.sha256 else {
            return nil
        }

        let decryptedData = externalData?.zmDecryptPrefixedPlainTextIV(
            key: external.otrKey
        )

        guard
            let base64String = decryptedData?.base64String(),
            let message = GenericMessage(from: base64String, validate: true)
        else { return nil }

        return message
    }

}
