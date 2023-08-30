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

    func allEmojis() -> [EmojiData]
    func emojis(for category: EmojiCategory) -> [EmojiData]
    func data(for emoji: Emoji) -> EmojiData?

}

final class EmojiRepository: EmojiRepositoryInterface {

    // MARK: - Properties

    private let allEmojiData: [EmojiData]
    private lazy var emojisByCategory = allEmojiData.partition(by: \.category)
    private lazy var emojisByValue = allEmojiData.partition(by: \.value).compactMapValues(\.first)

    private static let logger = WireLogger(tag: "EmojiRepository")

    // MARK: - Life cycle

    init() {
        allEmojiData = Self.loadAllFromDisk().sorted {
            $0.sortOrder < $1.sortOrder
        }
    }

    // MARK: - Methods

    func allEmojis() -> [EmojiData] {
        return allEmojiData
    }

    func emojis(for category: EmojiCategory) -> [EmojiData] {
        return emojisByCategory[category] ?? []
    }

    func data(for emoji: Emoji) -> EmojiData? {
        return emojisByValue[emoji.value]
    }

}

private extension EmojiRepository {

    static func loadAllFromDisk() -> [EmojiData] {
        guard let url = Bundle.main.url(forResource: "emojis", withExtension: "json") else {
            logger.error("failed to load emojis: emojis.json file not found")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([EmojiData].self, from: data)
        } catch {
            logger.error("failed to load emojis: \(error)")
            return []
        }
    }

}
