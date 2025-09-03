//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

/// A file cache
/// This class is NOT thread safe. However, the only problematic operation is deleting.
/// Any thread can read objects that are never deleted without any problem.
/// Objects purged from the cache folder by the OS are not a problem as the
/// OS will terminate the app before purging the cache.
public struct FileCache: Cache {

    private let cacheFolderURL: URL

    /// Create FileCahe
    /// - parameter location: where cache is persisted on disk.

    public init(location: URL) {
        self.cacheFolderURL = location
        try! FileManager.default.createAndProtectDirectory(at: cacheFolderURL)
    }

    public func assetData(_ key: String) -> Data? {
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

    public func storeAssetData(_ data: Data, key: String, createdAt creationDate: Date = Date()) {

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
                    .creationDate: creationDate
                ]
            )
        }

        if let error {
            WireLogger.assets.error("Failed storing asset data for key = \(key): \(error)")
        }
    }

    public func storeAssetFromURL(_ fromUrl: URL, key: String, createdAt creationDate: Date = Date()) {

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
                        .creationDate: creationDate
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

    public func deleteAssetData(_ key: String) {

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

    public func assetURL(_ key: String) -> URL? {
        let url = URLForKey(key)
        let isReachable = (try? url.checkResourceIsReachable()) ?? false
        return isReachable ? url : nil
    }

    public func hasDataForKey(_ key: String) -> Bool {
        assetURL(key) != nil
    }

    /// Returns the expected URL of a cache entry
    public func URLForKey(_ key: String) -> URL {
        guard key != ".", key != ".." else { fatal("Can't use \(key) as cache key") }
        var safeKey = key
        for c in ":\\/%\"" { // see https://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words
            safeKey = safeKey.replacingOccurrences(of: "\(c)", with: "_")
        }
        return cacheFolderURL.appendingPathComponent(safeKey)
    }

    /// Deletes the contents of the cache.

    public func wipeCaches() throws {
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
    public func deleteAssetsOlderThan(_ date: Date) throws {
        for expiredAsset in try assetsOlderThan(date) {
            try FileManager.default.removeItem(at: expiredAsset)
        }
    }

    /// Returns assets created earlier than the given date
    public func assetsOlderThan(_ date: Date) throws -> [URL] {
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
