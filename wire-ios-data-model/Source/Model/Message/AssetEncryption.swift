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

import Foundation
import WireProtos

extension FileAssetCache {


    // MARK: - Conversation message

    /// Encrypts a plaintext cache entry to an encrypted one, also computing the digest 
    /// of the encrypted entry.

    public func encryptImageAndComputeSHA256Digest(
        _ message: ZMConversationMessage,
        format: ZMImageFormat
    ) -> ZMImageAssetEncryptionKeys? {
        guard
            let plaintextCacheKey = Self.cacheKeyForAsset(
                message,
                format: format,
                encrypted: false
            ),
            let encryptedCacheKey = Self.cacheKeyForAsset(
                message,
                format: format,
                encrypted: true
            )
        else {
            return nil
        }

        let keys = encryptFileAndComputeSHA256Digest(
            plaintextCacheKey,
            encryptedEntryKey: encryptedCacheKey
        )

        cache.deleteAssetData(plaintextCacheKey)

        return keys
    }

    /// Encrypts a plaintext cache entry to an encrypted one, also computing the digest 
    /// of the encrypted entry.

    public func encryptFileAndComputeSHA256Digest(
        _ message: ZMConversationMessage
    ) -> ZMImageAssetEncryptionKeys? {
        guard
            let plaintextCacheKey = Self.cacheKeyForAsset(
                message,
                encrypted: false
            ),
            let encryptedCacheKey = Self.cacheKeyForAsset(
                message,
                encrypted: true
            )
        else {
            return nil
        }

        let keys = encryptFileAndComputeSHA256Digest(
            plaintextCacheKey,
            encryptedEntryKey: encryptedCacheKey
        )

        cache.deleteAssetData(plaintextCacheKey)

        return keys
    }

    /// Encrypts a plaintext cache entry to an encrypted one, also computing the digest 
    /// of the encrypted entry.

    private func encryptFileAndComputeSHA256Digest(
        _ plaintextEntryKey: String,
        encryptedEntryKey: String
    ) -> ZMImageAssetEncryptionKeys? {
        guard let plainData = assetData(plaintextEntryKey) else {
            return nil
        }

        let encryptionKey = Data.randomEncryptionKey()

        do {
            let encryptedData = try plainData.zmEncryptPrefixingPlainTextIV(key: encryptionKey)
            let hash = encryptedData.zmSHA256Digest()

            cache.storeAssetData(
                encryptedData,
                key: encryptedEntryKey,
                createdAt: Date()
            )

            return ZMImageAssetEncryptionKeys(
                otrKey: encryptionKey,
                sha256: hash
            )
        } catch {
            return nil
        }
    }

}
