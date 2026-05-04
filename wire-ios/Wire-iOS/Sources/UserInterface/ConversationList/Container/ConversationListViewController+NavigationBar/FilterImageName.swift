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

import WireMainNavigationUI

/// Enum representing different filter icons based on the user's selection.
enum FilterImageName: String {

    /// Represents an unselected text bubble icon for all conversations.
    case textBubble = "text.bubble"

    /// Represents a selected (filled) text bubble icon for all conversations.
    case textBubbleFill = "text.bubble.fill"

    /// Represents an unselected star icon for favorite conversations.
    case star

    /// Represents a selected (filled) star icon for favorite conversations.
    case starFill = "star.fill"

    /// Represents an unselected person icon for one-to-one conversations.
    case person

    /// Represents a selected (filled) person icon for one-to-one conversations.
    case personFill = "person.fill"

    /// Represents an unselected group icon, depicting three persons, for group conversations.
    case person3 = "person.3"

    /// Represents a selected (filled) group icon, depicting three persons, for group conversations.
    case person3Fill = "person.3.fill"

    /// Represents an unselected folder icon for a folder's conversations.
    case folder

    /// Represents a selected (filled) folder icon for a folder's conversations.
    case folderFill = "folder.fill"

    /// Represents a selected or unselected channel icon for channel conversations.
    case number

    /// Represents the unread icon - filled square with number 1
    case oneSquare = "1.square"

    /// Represents the selected unread icon - filled square with number 1
    case oneSquareFill = "1.square.fill"

    /// Represents the at symbol icon for mentions
    case at

    /// Represents the reply icon for replies
    case arrowshapeTurnUpLeft = "arrowshape.turn.up.left"

    /// Represents the draft icon - pencil and ellipsis in rectangle
    case pencilAndEllipsisRectangle = "pencil.and.ellipsis.rectangle"

    /// Represents the selected draft icon - pencil and ellipsis in rectangle (filled)
    case pencilAndEllipsisRectangleFill = "pencil.and.ellipsis.rectangle.fill"

    /// Returns the appropriate `FilterImageName` based on the type of conversation filter and its selection state.
    ///
    /// - Parameters:
    ///   - filter: The type of conversation filter. The `MainConversationFilter` enum is assumed to have the following
    /// cases:
    ///     - `.allConversations`: Represents all conversations.
    ///     - `.favorites`: Represents favorite conversations.
    ///     - `.groups`: Represents group conversations.
    ///     - `.oneToOneConversations`: Represents one-to-one conversations.
    ///   - isSelected: A boolean value indicating whether the filter is selected.
    /// - Returns: The corresponding `FilterImageName` based on the provided filter type and selection state.
    static func filterImageName(
        for filter: ConversationFilter?,
        isSelected: Bool
    ) -> FilterImageName {
        guard let filter else {
            return isSelected ? .textBubbleFill : .textBubble
        }

        switch filter {
        case .favorites:
            return isSelected ? .starFill : .star
        case .groups:
            return isSelected ? .person3Fill : .person3
        case .oneOnOne:
            return isSelected ? .personFill : .person
        case .folder:
            return isSelected ? .folderFill : .folder
        case .channels:
            return .number // Same icon is used for selected and unselected. Just the color changes.
        case .unread:
            return isSelected ? .oneSquareFill : .oneSquare
        case .mentions:
            return .at // Same icon for both states
        case .replies:
            return .arrowshapeTurnUpLeft // Same icon for both states
        case .drafts:
            return isSelected ? .pencilAndEllipsisRectangleFill : .pencilAndEllipsisRectangle
        }
    }
}
