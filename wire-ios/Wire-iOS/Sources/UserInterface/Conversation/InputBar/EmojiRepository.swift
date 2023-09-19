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
import WireUtilities

protocol EmojiRepositoryInterface {

    func allEmojis() -> [Emoji]
    func emojis(for category: EmojiCategory) -> [Emoji]
    func emoji(for id: String) -> Emoji?
    func registerRecentlyUsedEmojis(_ emojis: [Emoji])
    func fetchRecentlyUsedEmojis() -> [Emoji]

}

final class EmojiRepository: EmojiRepositoryInterface {

    // MARK: - Properties

    private let allEmojiData: [Emoji]
    private lazy var emojisByCategory = allEmojiData.partition(by: \.category)
    private lazy var emojisByID = allEmojiData.partition(by: \.id).compactMapValues(\.first)

    private static let logger = WireLogger(tag: "EmojiRepository")

    // MARK: - Life cycle

    init() {
        allEmojiData = Self.loadAllFromDisk().sorted {
            $0.sortOrder < $1.sortOrder
        }
    }

    // MARK: - Fetch

    func allEmojis() -> [Emoji] {
        return allEmojiData
    }

    func emojis(for category: EmojiCategory) -> [Emoji] {
        return emojisByCategory[category] ?? []
    }

    func emoji(for id: String) -> Emoji? {
        return emojisByID[id]
    }

    // MARK: - Recently used

    func registerRecentlyUsedEmojis(_ emojis: [Emoji]) {
        guard
            let emojiDirectory = emojiDirectory,
            let recentlyUsedEmojisURL = recentlyUsedEmojisURL
        else {
            return
        }

        FileManager.default.createAndProtectDirectory(at: emojiDirectory)
        let emojiValues = emojis.map(\.id)
        (emojiValues as NSArray).write(to: recentlyUsedEmojisURL, atomically: true)
    }

    func fetchRecentlyUsedEmojis() -> [Emoji] {
        guard
            let recentlyUsedEmojisURL = recentlyUsedEmojisURL,
            let emojiValues = NSArray(contentsOf: recentlyUsedEmojisURL) as? [String]
        else {
            return []
        }

        return emojiValues.compactMap(emoji(for:))
    }

    private lazy var emojiDirectory = URL.directoryURL("emoji")
    private lazy var recentlyUsedEmojisURL = emojiDirectory?.appendingPathComponent("recently_used.plist")

}

private extension EmojiRepository {

    static func loadAllFromDisk() -> [Emoji] {
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
