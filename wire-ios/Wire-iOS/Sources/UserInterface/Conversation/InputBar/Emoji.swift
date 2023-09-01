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

struct Emoji: Decodable, Hashable {

    typealias ID = String

    // TODO: rename value to id
    let value: String
    let name: String
    let shortName: String
    let category: EmojiCategory
    let subcategory: String
    let addedIn: String
    let sortOrder: Int

    func matchesSearchQuery(_ query: String) -> Bool {
        return [name, shortName, category.rawValue, subcategory].contains {
            $0.lowercased().contains(query)
        }
    }

}

extension Emoji {

    // We should have a basic set to load from.

    static let like = Emoji(
        value: "❤️",
        name: "heart",
        shortName: "heart",
        category: .symbols,
        subcategory: "",
        addedIn: "",
        sortOrder: 0
    )

}

extension Emoji {

    static func loadAllFromDisk() throws -> [Emoji] {
        guard let url = Bundle.main.url(
            forResource: "emojis",
            withExtension: "json"
        ) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(
            [Emoji].self,
            from: data
        )
    }

}

enum EmojiCategory: String, CaseIterable, Decodable {

    case smileysAndEmotion = "Smileys & Emotion"
    case peopleAndBody = "People & Body"
    case animalsAndNature = "Animals & Nature"
    case foodAndDrink = "Food & Drink"
    case activities = "Activities"
    case travelAndPlaces = "Travel & Places"
    case objects = "Objects"
    case symbols = "Symbols"
    case flags = "Flags"
    case component = "Component"

}
