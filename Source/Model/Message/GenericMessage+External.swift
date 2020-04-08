//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "GenericMessage")

extension GenericMessage {
    static func encryptedDataWithKeys(from message: GenericMessage) -> ZMExternalEncryptedDataWithKeys? {
        guard
            let aesKey = NSData.randomEncryptionKey(),
            let messageData = try? message.serializedData()
            else {
                return nil
        }
        let encryptedData = messageData.zmEncryptPrefixingPlainTextIV(key: aesKey)
        let keys = ZMEncryptionKeyWithChecksum.key(withAES: aesKey, digest: encryptedData.zmSHA256Digest())
        return ZMExternalEncryptedDataWithKeys(data: encryptedData, keys: keys)
    }
    
    init?(from updateEvent: ZMUpdateEvent, withExternal external: External) {
        guard let externalDataString = updateEvent.payload.optionalString(forKey: "external") else { return nil }
        let externalData = Data(base64Encoded: externalDataString)
        let externalSha256 = externalData?.zmSHA256Digest()
        
        guard externalSha256 == external.sha256 else {
            zmLog.error("Invalid hash for external data: \(externalSha256 ?? Data()) != \(external.sha256), updateEvent: \(updateEvent)")
            return nil
        }
        
        let decryptedData = externalData?.zmDecryptPrefixedPlainTextIV(key: external.otrKey)
        guard let message = GenericMessage(withBase64String: decryptedData?.base64String()) else {
            return nil
        }
        self = message
    }
}
