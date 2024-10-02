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

import UIKit
import WireCommonComponents
import WireDesign

final class EmojiDataSource: NSObject, UICollectionViewDataSource {

    // MARK: - Properties

    let cellProvider: CellProvider

    private let initialSections: [Section]
    private var sections: [Section]
    private let recentlyUsed: RecentlyUsedEmojiSection
    private let emojiRepository: EmojiRepositoryInterface

    var sectionTypes: [EmojiSectionType] {
        return sections.map(\.id)
    }

    // MARK: - Life cycle

    init(
        provider: @escaping CellProvider,
        emojiRepository: EmojiRepositoryInterface = EmojiRepository()
    ) {
        cellProvider = provider
        self.emojiRepository = emojiRepository

        let smileysAndEmotion = emojiRepository.emojis(for: .smileysAndEmotion)
        let peopleAndBody = emojiRepository.emojis(for: .peopleAndBody)
        let animalsAndNature = emojiRepository.emojis(for: .animalsAndNature)
        let foodAndDrink = emojiRepository.emojis(for: .foodAndDrink)
        let activities = emojiRepository.emojis(for: .activities)
        let travelAndPlaces = emojiRepository.emojis(for: .travelAndPlaces)
        let objects = emojiRepository.emojis(for: .objects)
        let symbols = emojiRepository.emojis(for: .symbols)
        let flags = emojiRepository.emojis(for: .flags)

        initialSections = [
            Section(id: .people, items: smileysAndEmotion + peopleAndBody),
            Section(id: .nature, items: animalsAndNature),
            Section(id: .food, items: foodAndDrink),
            Section(id: .activities, items: activities),
            Section(id: .travel, items: travelAndPlaces),
            Section(id: .objects, items: objects),
            Section(id: .symbols, items: symbols),
            Section(id: .flags, items: flags)
        ]

        recentlyUsed = RecentlyUsedEmojiSection(
            capacity: 15,
            items: emojiRepository.fetchRecentlyUsedEmojis()
        )

        sections = initialSections

        super.init()
        insertRecentlyUsedSectionIfNeeded()
    }

    // MARK: - Helpers

    subscript (index: Int) -> Section {
        return sections[index]
    }

    subscript (indexPath: IndexPath) -> Emoji {
        return sections[indexPath.section].items[indexPath.item]
    }

    func sectionIndex(for id: EmojiSectionType) -> Int? {
        return sections.firstIndex {
            $0.id == id
        }
    }

    // MARK: - Data source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return sections[section].items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        return cellProvider(self[indexPath], indexPath)
    }

    // MARK: - Filter

    func filterEmojis(withQuery query: String) {
        guard !query.isEmpty else {
            sections = initialSections
            insertRecentlyUsedSectionIfNeeded()
            return
        }

        let lowercasedQuery = query.lowercased()
        sections = initialSections.compactMap {
            $0.filteredBySearchQuery(lowercasedQuery)
        }
    }

    // MARK: - Recents

    @discardableResult
    func register(used emoji: Emoji) -> Update? {
        let shouldReload = recentlyUsed.register(emoji)
        let shouldInsert = insertRecentlyUsedSectionIfNeeded()

        defer {
            emojiRepository.registerRecentlyUsedEmojis(recentlyUsed.items.map(\.value))
        }

        switch (shouldInsert, shouldReload) {
        case (true, _): return .insert(0)
        case (false, true): return .reload(0)
        default: return nil
        }
    }

    @discardableResult
    func insertRecentlyUsedSectionIfNeeded() -> Bool {
        guard
            let first = sections.first,
            !(first is RecentlyUsedEmojiSection),
            !recentlyUsed.items.isEmpty
        else {
            return false
        }

        sections.insert(recentlyUsed, at: 0)
        return true
    }

}

extension EmojiDataSource {

    typealias CellProvider = (Emoji, IndexPath) -> UICollectionViewCell

    enum Update {

        case insert(Int)
        case reload(Int)

    }

    class Section {

        let id: EmojiSectionType
        var items: [Emoji]

        init(
            id: EmojiSectionType,
            items: [Emoji]
        ) {
            self.id = id
            self.items = items
        }

        func filteredBySearchQuery(_ query: String) -> Section? {
            guard !query.isEmpty else {
                return self
            }

            let filteredItems = items.filter {
                $0.matchesSearchQuery(query)
            }

            guard !filteredItems.isEmpty else {
                return nil
            }

            return Section(
                id: id,
                items: filteredItems
            )
        }

    }

}

enum EmojiSectionType: Int, CaseIterable {

    case recent
    case people
    case nature
    case food
    case travel
    case activities
    case objects
    case symbols
    case flags

    var icon: StyleKitIcon {
        switch self {
        case .recent: return .clock
        case .people: return .emoji
        case .nature: return .flower
        case .food: return .cake
        case .travel: return .car
        case .activities: return .ball
        case .objects: return .crown
        case .symbols: return .asterisk
        case .flags: return .flag
        }
    }

    var imageAsset: ImageResource {
        switch self {
        case .recent: return .recents
        case .people: return .smileysPeople
        case .nature: return .animalsNature
        case .food: return .foodDrink
        case .travel: return .travelPlaces
        case .activities: return .activity
        case .objects: return .objects
        case .symbols: return .symbols
        case .flags: return .flags
        }
    }
}
