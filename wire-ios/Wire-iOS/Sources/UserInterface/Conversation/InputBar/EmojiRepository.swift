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
import WireUtilities

// MARK: - EmojiRepositoryInterface

protocol EmojiRepositoryInterface {
    func emojis(for category: EmojiCategory) -> [Emoji]
    func emoji(for id: String) -> Emoji?
    func registerRecentlyUsedEmojis(_ emojis: [Emoji.ID])
    func fetchRecentlyUsedEmojis() -> [Emoji]
}

// MARK: - EmojiRepository

final class EmojiRepository: EmojiRepositoryInterface {
    // MARK: Lifecycle

    init() {
        self.allEmojiData = Self.loadAllFromDisk()
            .filter { Self.isEmojiAvailable($0) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: Internal

    // MARK: - Fetch

    func emojis(for category: EmojiCategory) -> [Emoji] {
        emojisByCategory[category] ?? []
    }

    func emoji(for id: String) -> Emoji? {
        emojisByValue[id]
    }

    // MARK: - Recently used

    func registerRecentlyUsedEmojis(_ emojis: [Emoji.ID]) {
        guard
            let emojiDirectory,
            let recentlyUsedEmojisURL
        else {
            return
        }

        try! FileManager.default.createAndProtectDirectory(at: emojiDirectory)
        (emojis as NSArray).write(to: recentlyUsedEmojisURL, atomically: true)
    }

    func fetchRecentlyUsedEmojis() -> [Emoji] {
        guard
            let recentlyUsedEmojisURL,
            let emojiValues = NSArray(contentsOf: recentlyUsedEmojisURL) as? [String]
        else {
            return []
        }

        return emojiValues.compactMap(emoji(for:))
    }

    // MARK: Private

    private static let logger = WireLogger(tag: "EmojiRepository")

    private static let supportedEmojiVersion =
        if #available(iOS 16.4, *) {
            15.0
        } else if #available(iOS 15.4, *) {
            14.0
        } else {
            13.1
        }

    // MARK: - Properties

    private let allEmojiData: [Emoji]
    private lazy var emojisByCategory = allEmojiData.partition(by: \.category)
    private lazy var emojisByValue = allEmojiData.partition(by: \.value).compactMapValues(\.first)

    private lazy var emojiDirectory = URL.directoryURL("emoji")
    private lazy var recentlyUsedEmojisURL = emojiDirectory?.appendingPathComponent("recently_used.plist")

    // MARK: - Availability

    private static func isEmojiAvailable(_ emoji: Emoji) -> Bool {
        guard let emojiVersion = Double(emoji.addedIn) else {
            return false
        }
        let emojiVersionTruncated = (emojiVersion * 100.0).rounded() / 100.0
        return emojiVersionTruncated <= supportedEmojiVersion
    }
}

extension EmojiRepository {
    fileprivate static func loadAllFromDisk() -> [Emoji] {
        guard let url = Bundle.main.url(forResource: "emojis", withExtension: "json") else {
            logger.error("failed to load emojis: emojis.json file not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Emoji].self, from: data)
        } catch {
            logger.error("failed to load emojis: \(error)")
            return []
        }
    }
}
