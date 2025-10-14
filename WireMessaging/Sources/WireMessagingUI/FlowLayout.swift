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

import SwiftUI

/// A view that organizes items into a grid similar to `UICollectionViewFlowLayout`.
struct FlowLayout: Layout {

    private struct Item {
        let size: CGSize
        let offset: CGPoint
    }

    let spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.replacingUnspecifiedDimensions().width
        return layout(subviews: subviews, containerWidth: containerWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let items = layout(subviews: subviews, containerWidth: bounds.width).items

        for (item, subview) in zip(items, subviews) {
            subview.place(
                at: CGPoint(x: item.offset.x + bounds.minX, y: item.offset.y + bounds.minY),
                proposal: .init(item.size)
            )
        }
    }

    // MARK: - Private

    private func layout(subviews: Subviews, containerWidth: CGFloat) -> (items: [Item], size: CGSize) {
        let sizes = subviews.map { subview in
            let size = subview.sizeThatFits(.unspecified)
            return CGSize(width: min(size.width, containerWidth), height: size.height)
        }

        var items: [Item] = []
        var offset = CGPoint.zero
        var currentLineHeight: Double = 0
        var maxX: Double = 0

        for size in sizes {
            let requiresNewLine = offset.x + size.width > containerWidth
            if requiresNewLine {
                offset.x = 0
                offset.y += currentLineHeight + spacing
                currentLineHeight = 0
            }

            items.append(Item(size: size, offset: offset))

            maxX = max(maxX, offset.x + size.width)
            offset.x += size.width + spacing
            currentLineHeight = max(currentLineHeight, size.height)
        }

        let totalHeight = offset.y + currentLineHeight
        return (items, CGSize(width: maxX, height: totalHeight))
    }

}

#Preview {
    FlowLayout {
        Rectangle()
            .fill(.red)
            .frame(width: 50, height: 50)

        Rectangle()
            .fill(.green)
            .frame(width: 50, height: 30)

        Rectangle()
            .fill(.blue)
            .frame(idealWidth: .infinity)
            .frame(height: 70)
    }
    .background(Color.yellow)
    .padding(8)
}
