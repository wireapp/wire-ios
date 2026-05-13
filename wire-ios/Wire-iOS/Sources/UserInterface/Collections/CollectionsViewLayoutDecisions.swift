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

import UIKit

struct CollectionsViewLayoutDecisions {
    static let maxOverviewElementsInTable = 3

    static func shouldShowNoItems(fetchingDone: Bool, inOverviewMode: Bool, totalNumberOfElements: Int) -> Bool {
        fetchingDone && inOverviewMode && totalNumberOfElements == 0
    }

    static func sectionInsets(for section: CollectionsSectionSet, isEmpty: Bool) -> UIEdgeInsets {
        if section == .loading || section == .searchFiles {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }

        return isEmpty ? .zero : UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)
    }

    static func headerSize(for section: CollectionsSectionSet, isEmpty: Bool, collectionWidth: CGFloat) -> CGSize {
        if section == .loading || section == .searchFiles || isEmpty {
            return .zero
        }

        return CGSize(width: collectionWidth, height: 48)
    }

    static func cellSize(
        for section: CollectionsSectionSet,
        collectionWidth: CGFloat,
        horizontalInset: CGFloat,
        gridElementSize: CGSize,
        fetchingDone: Bool,
        usesAutolayout: Bool
    ) -> (width: CGFloat?, height: CGFloat?) {
        var desiredWidth: CGFloat?
        var desiredHeight: CGFloat?

        switch section {
        case .images, .videos:
            desiredWidth = gridElementSize.width
            desiredHeight = gridElementSize.height

        case .filesAndAudio:
            desiredWidth = collectionWidth - horizontalInset
            if !usesAutolayout {
                desiredHeight = 96
            }

        case .links:
            desiredWidth = collectionWidth - horizontalInset
            if !usesAutolayout {
                desiredHeight = 98
            }

        case .loading:
            desiredWidth = collectionWidth - horizontalInset
            if !usesAutolayout {
                desiredHeight = fetchingDone ? 24 : 88
            }

        case .searchFiles:
            desiredWidth = collectionWidth - horizontalInset
            if !usesAutolayout {
                desiredHeight = 50
            }

        default:
            fatalError("Unknown section")
        }

        return (desiredWidth, desiredHeight)
    }
}
