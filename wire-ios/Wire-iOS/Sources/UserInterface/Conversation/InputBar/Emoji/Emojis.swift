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

// MARK: - EmojiDataSource

final class EmojiDataSource: NSObject, UICollectionViewDataSource {
    // MARK: Lifecycle

    init(
        provider: @escaping CellProvider,
        emojiRepository: EmojiRepositoryInterface = EmojiRepository()
    ) {
        self.cellProvider = provider
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

        self.initialSections = [
            Section(id: .people, items: smileysAndEmotion + peopleAndBody),
            Section(id: .nature, items: animalsAndNature),
            Section(id: .food, items: foodAndDrink),
            Section(id: .activities, items: activities),
            Section(id: .travel, items: travelAndPlaces),
            Section(id: .objects, items: objects),
            Section(id: .symbols, items: symbols),
            Section(id: .flags, items: flags),
        ]

        self.recentlyUsed = RecentlyUsedEmojiSection(
            capacity: 15,
            items: emojiRepository.fetchRecentlyUsedEmojis()
        )

        self.sections = initialSections

        super.init()
        insertRecentlyUsedSectionIfNeeded()
    }

    // MARK: Internal

    // MARK: - Properties

    let cellProvider: CellProvider

    var sectionTypes: [EmojiSectionType] {
        sections.map(\.id)
    }

    // MARK: - Helpers

    subscript(index: Int) -> Section {
        sections[index]
    }

    subscript(indexPath: IndexPath) -> Emoji {
        sections[indexPath.section].items[indexPath.item]
    }

    func sectionIndex(for id: EmojiSectionType) -> Int? {
        sections.firstIndex {
            $0.id == id
        }
    }

    // MARK: - Data source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sections[section].items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        cellProvider(self[indexPath], indexPath)
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

    // MARK: Private

    private let initialSections: [Section]
    private var sections: [Section]
    private let recentlyUsed: RecentlyUsedEmojiSection
    private let emojiRepository: EmojiRepositoryInterface
}

extension EmojiDataSource {
    typealias CellProvider = (Emoji, IndexPath) -> UICollectionViewCell

    enum Update {
        case insert(Int)
        case reload(Int)
    }

    class Section {
        // MARK: Lifecycle

        init(
            id: EmojiSectionType,
            items: [Emoji]
        ) {
            self.id = id
            self.items = items
        }

        // MARK: Internal

        let id: EmojiSectionType
        var items: [Emoji]

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

// MARK: - EmojiSectionType

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

    // MARK: Internal

    var icon: StyleKitIcon {
        switch self {
        case .recent: .clock
        case .people: .emoji
        case .nature: .flower
        case .food: .cake
        case .travel: .car
        case .activities: .ball
        case .objects: .crown
        case .symbols: .asterisk
        case .flags: .flag
        }
    }

    var imageAsset: ImageResource {
        switch self {
        case .recent: .recents
        case .people: .smileysPeople
        case .nature: .animalsNature
        case .food: .foodDrink
        case .travel: .travelPlaces
        case .activities: .activity
        case .objects: .objects
        case .symbols: .symbols
        case .flags: .flags
        }
    }
}
