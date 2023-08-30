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
import UIKit
import WireCommonComponents

@objc
final class Emoji: NSObject {

    let value: String
    let name: String?

    init(value: String) {
        self.value = value
        self.name = value.unicodeScalars.first?.properties.name?.lowercased()
    }

    override var description: String {
        return value
    }

    override var hash: Int {
        return value.hash
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Emoji else { return false }
        return value == other.value
    }

}

extension Emoji {

    static var like: Emoji {
        return Emoji(value: "❤️")
    }

    static var smile: Emoji {
        return Emoji(value: "🙂")
    }

    static var frown: Emoji {
        return Emoji(value: "☹️")
    }

    static var thumbsUp: Emoji {
        return Emoji(value: "👍")
    }

    static var thumbsDown: Emoji {
        return Emoji(value: "👎")
    }

}

final class EmojiDataSource: NSObject, UICollectionViewDataSource {

    // MARK: - Properties

    let cellProvider: CellProvider

    private let initialSections: [Section]
    private var sections: [EmojiDataSourceSection]
    private let recentlyUsed: RecentlyUsedEmojiSection

    // MARK: - Life cycle

    init(provider: @escaping CellProvider) {
        cellProvider = provider
        recentlyUsed = RecentlyUsedEmojiPeristenceCoordinator.loadOrCreate()
        initialSections = Self.loadEmojiSections()
        sections = initialSections
        super.init()
        insertRecentlyUsedSectionIfNeeded()
    }

    // MARK: - Helpers

    private static func loadEmojiSections() -> [Section] {
        guard let emojis = try? EmojiData.loadAllFromDisk() else {
            return []
        }

        return emojis
            .sorted { $0.sortOrder < $1.sortOrder }
            .partition(by: \.category.sectionID)
            .map(Section.init)
            .sorted { $0.id.rawValue < $1.id.rawValue }
    }

    subscript (index: Int) -> EmojiDataSourceSection {
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

        defer { RecentlyUsedEmojiPeristenceCoordinator.store(recentlyUsed) }
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

protocol EmojiDataSourceSection {

    var id: EmojiSectionType { get }
    var items: [Emoji] { get }

}

extension EmojiDataSource {

    typealias CellProvider = (Emoji, IndexPath) -> UICollectionViewCell

    enum Update {

        case insert(Int)
        case reload(Int)

    }

    final class Section: EmojiDataSourceSection {

        let id: EmojiSectionType
        let image: ImageAsset
        let emojiData: [EmojiData]
        let items: [Emoji]

        convenience init(
            id: EmojiSectionType,
            emojiData: [EmojiData]
        ) {
            self.init(
                id: id,
                image: id.imageAsset,
                emojiData: emojiData
            )
        }

        init(
            id: EmojiSectionType,
            image: ImageAsset,
            emojiData: [EmojiData]
        ) {
            self.id = id
            self.image = image
            self.emojiData = emojiData
            self.items = emojiData.map { Emoji(value: $0.value) }
        }

        func filteredBySearchQuery(_ query: String) -> Section? {
            guard !query.isEmpty else {
                return self
            }

            let filteredData = emojiData.filter {
                $0.matchesSearchQuery(query)
            }

            guard !filteredData.isEmpty else {
                return nil
            }

            return Section(
                id: id,
                image: image,
                emojiData: filteredData
            )
        }

    }

}

// TODO: rename EmojiDataSource.SectionID
enum EmojiSectionType: Int {

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

    var imageAsset: ImageAsset {
        switch self {
        case .recent: return Asset.Images.recents
        case .people: return Asset.Images.smileysPeople
        case .nature: return Asset.Images.animalsNature
        case .food: return Asset.Images.foodDrink
        case .travel: return Asset.Images.travelPlaces
        case .activities: return Asset.Images.activity
        case .objects: return Asset.Images.objects
        case .symbols: return Asset.Images.symbols
        case .flags: return Asset.Images.flags
        }
    }

    // TODO: to delete?
    static var all: [EmojiSectionType] {
        var all = basicTypes
        all.insert(EmojiSectionType.recent, at: 0)
        return all
    }

    // TODO: to delete?
    static var basicTypes: [EmojiSectionType] {
        return [
            .people,
            .nature,
            .food,
            .travel,
            .activities,
            .objects,
            .symbols,
            .flags
        ]
    }

}

private extension EmojiCategory {

    var sectionID: EmojiSectionType? {
        switch self {
        case .smileysAndEmotion, .peopleAndBody:
            return .people

        case .animalsAndNature:
            return .nature

        case .foodAndDrink:
            return .food

        case .activities:
            return .activities

        case .travelAndPlaces:
            return .travel

        case .objects:
            return .objects

        case .symbols:
            return .symbols

        case .flags:
            return .flags

        case .component:
            return nil
        }
    }

}
