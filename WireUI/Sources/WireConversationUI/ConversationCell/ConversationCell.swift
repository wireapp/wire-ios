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

public struct HorizontalMargins {
    var left: CGFloat
    var right: CGFloat
    
    public init(left: CGFloat, right: CGFloat) {
        self.left = left
        self.right = right
    }
    
    static var `default`: HorizontalMargins {
        .init(left: 56, right: 16)
    }
}

public final class ConversationCell: UITableViewCell {
    
    public var model: ConversationCellModel?
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        contentView.transform = .identity
    }

    public func configure(model: ConversationCellModel?, horizontalMargins: HorizontalMargins) {
        guard let model else { return }
        contentConfiguration = UIHostingConfiguration {
            switch model {
            case let .timeDivider(model):
                TimeDividerContentView(model: model)
            case let .text(model):
                TextMessageView(model: model)
            }
        }
        .margins(.vertical, 0)
        .margins(.leading, horizontalMargins.left)
        .margins(.trailing, horizontalMargins.right)
        .minSize(width: 0, height: 0)
        .background(.clear)
    }

}

// MARK: - Previews

// @available(iOS 17, *)
// #Preview {
//    ConversationCellsPreview(
//        itemIdentifiers: [
//            .timeDivider(text: "Friday", isUnread: false),
//            .timeDivider(text: "Saturday", isUnread: false),
//            .timeDivider(text: "Today", isUnread: true)
//        ]
//    )
// }
