//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct CollectionsViewModel {
    private static let maxOverviewElementsInTable = 3

    let sections: CollectionsSectionSet
    let isCellsEnabled: Bool
    var fetchingDone: Bool

    var visibleSections: [CollectionsSectionSet] {
        isCellsEnabled ? CollectionsSectionSet.visibleWithSearchFiles : CollectionsSectionSet.visible
    }

    var inOverviewMode: Bool {
        sections == .all
    }

    var reloadableMediaSections: [CollectionsSectionSet] {
        [.images, .videos]
    }

    func section(at index: Int) -> CollectionsSectionSet? {
        guard visibleSections.indices.contains(index) else {
            return nil
        }

        return visibleSections[index]
    }

    func index(of section: CollectionsSectionSet) -> Int? {
        visibleSections.firstIndex(of: section)
    }

    func numberOfSections() -> Int {
        visibleSections.count
    }

    func numberOfElements(
        for section: CollectionsSectionSet,
        counts: CollectionsViewModel.ElementCounts,
        maxOverviewElementsInGrid: Int
    ) -> Int {
        switch section {
        case .images:
            let max = inOverviewMode ? maxOverviewElementsInGrid : Int.max
            return min(counts.images, max)

        case .filesAndAudio:
            let max = inOverviewMode ? Self.maxOverviewElementsInTable : Int.max
            return min(counts.filesAndAudio, max)

        case .videos:
            let max = inOverviewMode ? maxOverviewElementsInGrid : Int.max
            return min(counts.videos, max)

        case .links:
            let max = inOverviewMode ? Self.maxOverviewElementsInTable : Int.max
            return min(counts.links, max)

        case .loading, .searchFiles:
            return 1

        default:
            fatalError("Unknown section")
        }
    }

    func totalNumberOfElements(
        counts: CollectionsViewModel.ElementCounts,
        maxOverviewElementsInGrid: (CollectionsSectionSet) -> Int
    ) -> Int {
        // Empty collection contains one element (loading cell).
        visibleSections
            .map { section in
                numberOfElements(
                    for: section,
                    counts: counts,
                    maxOverviewElementsInGrid: maxOverviewElementsInGrid(section)
                )
            }
            .reduce(0, +) - 1
    }

    func hasMoreElements(
        in section: CollectionsSectionSet,
        counts: CollectionsViewModel.ElementCounts,
        maxOverviewElementsInGrid: Int
    ) -> Bool {
        counts[section] > numberOfElements(
            for: section,
            counts: counts,
            maxOverviewElementsInGrid: maxOverviewElementsInGrid
        )
    }

    func shouldShowNoItems(
        counts: CollectionsViewModel.ElementCounts,
        maxOverviewElementsInGrid: (CollectionsSectionSet) -> Int
    ) -> Bool {
        fetchingDone && inOverviewMode && totalNumberOfElements(
            counts: counts,
            maxOverviewElementsInGrid: maxOverviewElementsInGrid
        ) == 0
    }
}

extension CollectionsViewModel {
    struct ElementCounts {
        let images: Int
        let filesAndAudio: Int
        let videos: Int
        let links: Int

        subscript(section: CollectionsSectionSet) -> Int {
            switch section {
            case .images:
                images
            case .filesAndAudio:
                filesAndAudio
            case .videos:
                videos
            case .links:
                links
            default:
                0
            }
        }
    }
}
