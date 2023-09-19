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

final class Emoji: Decodable {

    typealias ID = String

    let value: ID
    let name: String
    let shortName: String
    let category: EmojiCategory
    let subcategory: String
    let addedIn: String
    let sortOrder: Int

    let nameLocalizationKey: String?
    let tagsLocalizationKey: String?

    lazy var localizedName: String? = {
        guard let key = nameLocalizationKey else {
            return nil
        }

        return Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: "Emoji"
        )
    }()

    lazy var localizedTags: Set<String>? = {
        guard let key = tagsLocalizationKey else {
            return nil
        }

        let tagsString = Bundle.main.localizedString(
            forKey: key,
            value: nil,
            table: "Emoji"
        )

        let tags = tagsString
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        return Set(tags)
    }()

    func matchesSearchQuery(_ query: String) -> Bool {
        let query = query.lowercased()
        let tags = localizedTags ?? [name, shortName, category.rawValue, subcategory]
        return tags.contains {
            $0.lowercased().contains(query)
        }
    }

}

extension Emoji: Hashable {

    static func == (lhs: Emoji, rhs: Emoji) -> Bool {
        return lhs.value == rhs.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
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
