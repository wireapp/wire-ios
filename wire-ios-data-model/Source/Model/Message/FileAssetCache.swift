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

private let NSManagedObjectContextFileAssetCacheKey = "zm_fileAssetCache"

extension NSManagedObjectContext {
    @objc public var zm_fileAssetCache: FileAssetCache! {
        get {
            userInfo[NSManagedObjectContextFileAssetCacheKey] as? FileAssetCache
        }

        set {
            userInfo[NSManagedObjectContextFileAssetCacheKey] = newValue
        }
    }
}

// MARK: - FileAssetCache

/// A file cache
///
/// This class is NOT thread safe. However, the only problematic operation is deleting.
/// Any thread can read objects that are never deleted without any problem. Objects purged
/// from the cache folder by the OS are not a problem as the OS will terminate the app
/// before purging the cache.

@objcMembers
public final class FileAssetCache: NSObject {
    private let fileCache: FileCache
    private let tempCache: FileCache

    var cache: Cache {
        fileCache
    }

    /// Creates an asset cache.

    public init(location: URL) {
        let tempLocation = location.appendingPathComponent("temp")
        self.fileCache = FileCache(location: location)
        self.tempCache = FileCache(location: tempLocation)
        super.init()
    }

    // MARK: - Team logo

    private func cacheKey(
        for team: Team,
        format: ZMImageFormat
    ) -> String? {
        guard
            let teamID = team.remoteIdentifier?.uuidString,
            let assetID = team.pictureAssetId
        else {
            return nil
        }

        return [teamID, assetID, format.stringValue]
            .joined(separator: "_")
            .data(using: .utf8)?
            .zmSHA256Digest()
            .zmHexEncodedString()
    }

    public func storeImage(
        data: Data,
        for team: Team
    ) {
        guard let key = cacheKey(
            for: team,
            format: .medium
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: Date()
        )
    }

    @objc(hasImageDataForTeam:)
    public func hasImageData(for team: Team) -> Bool {
        guard let key = cacheKey(
            for: team,
            format: .medium
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func imageData(for team: Team) -> Data? {
        guard let key = cacheKey(
            for: team,
            format: .medium
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deleteImageData(for team: Team) {
        guard let key = cacheKey(
            for: team,
            format: .medium
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    // MARK: - Original images

    @objc(storeOriginalImageData:forMessage:)
    public func storeOriginalImage(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .original,
            encrypted: false
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasOriginalImageData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .original,
            encrypted: false
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func originalImageData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .original,
            encrypted: false
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deleteOriginalImageData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .original,
            encrypted: false
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    // MARK: - Medium images

    @objc(storeMediumImageData:forMessage:)
    public func storeMediumImage(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: false
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasMediumImageData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: false
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func mediumImageData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: false
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deleteMediumImageData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: false
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    // MARK: - Encrypted images

    public func encryptMediumImage(for message: ZMConversationMessage) -> ZMImageAssetEncryptionKeys? {
        encryptImageAndComputeSHA256Digest(
            message,
            format: .medium
        )
    }

    public func storeEncryptedMediumImage(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: true
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasEncryptedMediumImageData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: true
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func encryptedMediumImageData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: true
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deleteMediumEncryptedImageData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: true
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    public func decryptedMediumImageData(
        for message: ZMConversationMessage,
        encryptionKey: Data,
        sha256Digest: Data
    ) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .medium,
            encrypted: true
        ) else {
            return nil
        }

        return decryptData(
            key: key,
            encryptionKey: encryptionKey,
            sha256Digest: sha256Digest
        )
    }

    // MARK: - Preview images

    @objc(storePreviewImageData:forMessage:)
    public func storePreviewImage(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: false
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasPreviewImageData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: false
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func previewImageData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: false
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deletePreviewImageData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: false
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    // MARK: - Encrypted preview

    public func storeEncryptedPreviewImage(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: true
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func encryptedPreviewImageData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            format: .preview,
            encrypted: true
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    // MARK: - Original file

    public func storeOriginalFile(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: false
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasOriginalFileData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: false
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func originalFileData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: false
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func deleteOriginalFileData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: false
        ) else {
            return
        }

        return cache.deleteAssetData(key)
    }

    // MARK: - Encrypted file

    public func storeEncryptedFile(
        data: Data,
        for message: ZMConversationMessage
    ) {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: true
        ) else {
            return
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )
    }

    public func hasEncryptedFileData(for message: ZMConversationMessage) -> Bool {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: true
        ) else {
            return false
        }

        return cache.hasDataForKey(key)
    }

    public func encryptedFileData(for message: ZMConversationMessage) -> Data? {
        guard let key = Self.cacheKeyForAsset(
            message,
            encrypted: true
        ) else {
            return nil
        }

        return cache.assetData(key)
    }

    public func temporaryURLForDecryptedFile(
        for message: ZMConversationMessage,
        encryptionKey: Data,
        sha256Digest: Data
    ) -> URL? {
        guard let unencryptedKey = Self.cacheKeyForAsset(
            message,
            encrypted: false
        ) else {
            return nil
        }

        // We already have a temp url for the decrypted asset.
        if let url = tempCache.assetURL(unencryptedKey) {
            return url
        }

        // We need to decrypt the asset and store it in temp.
        guard
            let encryptedKey = Self.cacheKeyForAsset(
                message,
                encrypted: true
            ),
            let decryptedData = decryptData(
                key: encryptedKey,
                encryptionKey: encryptionKey,
                sha256Digest: sha256Digest
            )
        else {
            return nil
        }

        tempCache.storeAssetData(
            decryptedData,
            key: unencryptedKey,
            createdAt: message.serverTimestamp ?? Date()
        )

        return tempCache.assetURL(unencryptedKey)
    }

    // MARK: - Upload request data

    public func storeTransportData(
        _ data: Data,
        for message: ZMConversationMessage
    ) -> URL? {
        guard let key = Self.cacheKeyForAsset(
            message,
            identifier: "transport"
        ) else {
            return nil
        }

        cache.storeAssetData(
            data,
            key: key,
            createdAt: message.serverTimestamp ?? Date()
        )

        return cache.assetURL(key)
    }

    public func deleteTransportData(for message: ZMConversationMessage) {
        guard let key = Self.cacheKeyForAsset(
            message,
            identifier: "transport"
        ) else {
            return
        }

        cache.deleteAssetData(key)
    }

    // MARK: - Encryption

    /// Encrypts a plaintext cache entry to an encrypted one, also computing the digest
    /// of the encrypted entry.

    func encryptImageAndComputeSHA256Digest(
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

    func encryptFileAndComputeSHA256Digest(
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

    // MARK: - Decryption

    public func decryptData(
        key: String,
        encryptionKey: Data,
        sha256Digest: Data
    ) -> Data? {
        // Workaround: when decrypting data for the link preview, the key
        // and digest are sometimes empty (not sure why). An empty digest
        // will always fail the digest check and result in deleting the
        // asset forever. As a workaround, just return nil with these
        // invalid empty inputs, so next time the asset is fetched with
        // valid inputs it will succeed.
        guard
            !encryptionKey.isEmpty,
            !sha256Digest.isEmpty
        else {
            return nil
        }

        guard let encryptedData = cache.assetData(key) else {
            return nil
        }

        guard encryptedData.zmSHA256Digest() == sha256Digest else {
            cache.deleteAssetData(key)
            return nil
        }

        return encryptedData.zmDecryptPrefixedPlainTextIV(key: encryptionKey)
    }

    // MARK: - Purge

    public func purgeTemporaryAssets() throws {
        try tempCache.wipeCaches()
    }

    // MARK: - Asset data

    public func assetData(_ key: String) -> Data? {
        cache.assetData(key)
    }

    // MARK: - Conversation message

    @objc(hasImageDataForMessage:)
    public func hasImageData(for message: ZMConversationMessage) -> Bool {
        hasOriginalImageData(for: message)
            || hasMediumImageData(for: message)
            || hasEncryptedMediumImageData(for: message)
    }

    @objc(hasFileDataForMessage:)
    public func hasFileData(for message: ZMConversationMessage) -> Bool {
        hasOriginalFileData(for: message) || hasEncryptedFileData(for: message)
    }

    /// Returns the asset URL for a given message.

    public func accessAssetURL(_ message: ZMConversationMessage) -> URL? {
        guard let key = Self.cacheKeyForAsset(message) else {
            return nil
        }

        return cache.assetURL(key)
    }

    /// Deletes all associated data for a given message.
    ///
    /// This will cause I/O.

    public func deleteAssetData(_ message: ZMConversationMessage) {
        if message.imageMessageData != nil {
            let imageFormats: [ZMImageFormat] = [.medium, .original, .preview]

            for format in imageFormats {
                if let key = Self.cacheKeyForAsset(
                    message,
                    format: format,
                    encrypted: false
                ) {
                    cache.deleteAssetData(key)
                }

                if let key = Self.cacheKeyForAsset(
                    message,
                    format: format,
                    encrypted: true
                ) {
                    cache.deleteAssetData(key)
                }
            }
        }

        if message.fileMessageData != nil {
            if let key = Self.cacheKeyForAsset(
                message,
                encrypted: false
            ) {
                cache.deleteAssetData(key)
            }

            if let key = Self.cacheKeyForAsset(
                message,
                encrypted: true
            ) {
                cache.deleteAssetData(key)
            }
        }
    }

    public func deleteAssetsOlderThan(_ date: Date) {
        do {
            try cache.deleteAssetsOlderThan(date)
        } catch {
            WireLogger.assets.error("Error trying to delete assets older than \(date): \(error)")
        }
    }

    public static func cacheKeyForAsset(
        _ message: ZMConversationMessage,
        format: ZMImageFormat,
        encrypted: Bool = false
    ) -> String? {
        cacheKeyForAsset(
            message,
            identifier: format.stringValue,
            encrypted: encrypted
        )
    }

    public static func cacheKeyForAsset(
        _ message: ZMConversationMessage,
        identifier: String? = nil,
        encrypted: Bool = false
    ) -> String? {
        guard
            let messageId = message.nonce?.transportString(),
            let senderId = message.sender?.remoteIdentifier?.transportString(),
            let conversationId = message.conversation?.remoteIdentifier?.transportString()
        else {
            return nil
        }

        let key = [messageId, senderId, conversationId, identifier, encrypted ? "encrypted" : nil]
            .compactMap { $0 }
            .joined(separator: "_")

        return key.data(using: .utf8)?
            .zmSHA256Digest()
            .zmHexEncodedString()
    }
}

// MARK: - Testing

extension FileAssetCache {
    /// Deletes all existing caches. After calling this method, existing caches should not be used anymore.
    /// This is intended for testing
    public func wipeCaches() throws {
        try fileCache.wipeCaches()
        try tempCache.wipeCaches()
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalFileAttributeKeyDictionary(_ input: [String: Any]?) -> [FileAttributeKey: Any]? {
    guard let input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (FileAttributeKey(rawValue: key), value) })
}

// MARK: - FileCache

/// A file cache
/// This class is NOT thread safe. However, the only problematic operation is deleting.
/// Any thread can read objects that are never deleted without any problem.
/// Objects purged from the cache folder by the OS are not a problem as the
/// OS will terminate the app before purging the cache.
private struct FileCache: Cache {
    private let cacheFolderURL: URL

    /// Create FileCahe
    /// - parameter location: where cache is persisted on disk.

    init(location: URL) {
        self.cacheFolderURL = location
        try! FileManager.default.createAndProtectDirectory(at: cacheFolderURL)
    }

    func assetData(_ key: String) -> Data? {
        let url = URLForKey(key)
        let coordinator = NSFileCoordinator()
        var data: Data?

        var error: NSError?
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { url in
            do {
                data = try Data(contentsOf: url, options: .mappedIfSafe)
            } catch let error as NSError {
                if error.code != NSFileReadNoSuchFileError {
                    WireLogger.assets.error("\(error)")
                }
            }
        }

        if let error {
            if error.code != NSFileReadNoSuchFileError {
                WireLogger.assets.error("Failed reading asset data for key = \(key): \(error)")
            }
        }

        return data
    }

    func storeAssetData(_ data: Data, key: String, createdAt creationDate: Date = Date()) {
        let url = URLForKey(key)
        let coordinator = NSFileCoordinator()

        var error: NSError?
        coordinator.coordinate(
            writingItemAt: url,
            options: NSFileCoordinator.WritingOptions.forReplacing,
            error: &error
        ) { url in
            FileManager.default.createFile(
                atPath: url.path,
                contents: data,
                attributes: [
                    .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                    .creationDate: creationDate,
                ]
            )
        }

        if let error {
            WireLogger.assets.error("Failed storing asset data for key = \(key): \(error)")
        }
    }

    func storeAssetFromURL(_ fromUrl: URL, key: String, createdAt creationDate: Date = Date()) {
        guard fromUrl.scheme == NSURLFileScheme else { fatal("Can't save remote URL to cache: \(fromUrl)") }

        let toUrl = URLForKey(key)
        let coordinator = NSFileCoordinator()

        var error: NSError?
        coordinator.coordinate(writingItemAt: toUrl, options: .forReplacing, error: &error) { url in
            do {
                try FileManager.default.copyItem(at: fromUrl, to: url)
                try FileManager.default.setAttributes(
                    [
                        .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                        .creationDate: creationDate,
                    ],
                    ofItemAtPath: url.path
                )
            } catch {
                fatal("Failed to copy from \(url) to \(url), \(error)")
            }
        }

        if let error {
            WireLogger.assets.error("Failed to copy asset data from \(fromUrl)  for key = \(key): \(error)")
        }
    }

    func deleteAssetData(_ key: String) {
        let url = URLForKey(key)
        let coordinator = NSFileCoordinator()

        var error: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &error) { url in
            do {
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                if error.domain != NSCocoaErrorDomain || error.code != NSFileNoSuchFileError {
                    WireLogger.assets.error("Can't delete file \(url.pathComponents.last!): \(error)")
                }
            }
        }

        if let error {
            WireLogger.assets.error("Failed deleting asset data for key = \(key): \(error)")
        }
    }

    func assetURL(_ key: String) -> URL? {
        let url = URLForKey(key)
        let isReachable = (try? url.checkResourceIsReachable()) ?? false
        return isReachable ? url : nil
    }

    func hasDataForKey(_ key: String) -> Bool {
        assetURL(key) != nil
    }

    /// Returns the expected URL of a cache entry
    fileprivate func URLForKey(_ key: String) -> URL {
        guard key != ".", key != ".." else { fatal("Can't use \(key) as cache key") }
        var safeKey = key
        for c in ":\\/%\"" { // see https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
            safeKey = safeKey.replacingOccurrences(of: "\(c)", with: "_")
        }
        return cacheFolderURL.appendingPathComponent(safeKey)
    }

    /// Deletes the contents of the cache.

    func wipeCaches() throws {
        if FileManager.default.fileExists(atPath: cacheFolderURL.path) {
            // Delete the entire cache.
            try FileManager.default.removeItem(at: cacheFolderURL)
        }

        // Create it again so we can write files to it.
        try FileManager.default.createAndProtectDirectory(at: cacheFolderURL)
    }

    /// Deletes assets created earlier than the given date
    ///
    /// - parameter date: assets earlier than this date will be deleted
    func deleteAssetsOlderThan(_ date: Date) throws {
        for expiredAsset in try assetsOlderThan(date) {
            try FileManager.default.removeItem(at: expiredAsset)
        }
    }

    /// Returns assets created earlier than the given date
    func assetsOlderThan(_ date: Date) throws -> [URL] {
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(
            at: cacheFolderURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsSubdirectoryDescendants]
        )

        return try files.filter { file -> Bool in
            let attributes = try fileManager.attributesOfItem(atPath: file.path)

            guard let creationDate = attributes[.creationDate] as? Date else { return true }

            return creationDate < date
        }
    }
}
