//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// A flow layout that doesn't distribute the space between items equally, but instead fills the space from the left and
/// starts a new row if the next item doesn't fit anymore.
final class MessageReactionsCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()

        minimumInteritemSpacing = 8
        minimumLineSpacing = 8
        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Get the default attributes from the superclass
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        // Create a copy to avoid modifying read-only attributes
        let attributesCopy = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        for attribute in attributesCopy where attribute.representedElementCategory == .cell {
            // If this cell is on a new line, reset the left margin
            if attribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            // Set the x position of the cell to the left margin
            attribute.frame.origin.x = leftMargin
            // Update the left margin for the next cell
            leftMargin += attribute.frame.width + minimumInteritemSpacing
            // Update the maximum y value for this row
            maxY = max(attribute.frame.maxY, maxY)
        }
        return attributesCopy
    }
}
