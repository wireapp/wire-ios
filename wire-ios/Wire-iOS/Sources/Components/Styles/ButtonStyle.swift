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
import WireDesign

// Define a struct for state-specific colors
struct ButtonStateColors {
    let background: () -> UIColor
    let title: UIColor
    let border: UIColor?

    init(background: @escaping () -> UIColor, title: UIColor, border: UIColor? = nil) {
        self.background = background
        self.title = title
        self.border = border
    }
}

@available(*, deprecated, message: "should use WireDesign's WireButtonStyle instead")

struct ButtonStyle {

    typealias ButtonColors = SemanticColors.Button

    let normalStateColors: ButtonStateColors
    let highlightedStateColors: ButtonStateColors
    let selectedStateColors: ButtonStateColors?

    // Primary initializer
    init(
        normalStateColors: ButtonStateColors,
        highlightedStateColors: ButtonStateColors,
        selectedStateColors: ButtonStateColors? = nil
    ) {
        self.normalStateColors = normalStateColors
        self.highlightedStateColors = highlightedStateColors
        self.selectedStateColors = selectedStateColors
    }

    // Convenience initializer for styles where highlighted state only changes background
    init(
        normalStateColors: ButtonStateColors,
        highlightedBackground: @escaping () -> UIColor,
        selectedStateColors: ButtonStateColors? = nil
    ) {
        self.normalStateColors = normalStateColors
        self.highlightedStateColors = ButtonStateColors(
            background: highlightedBackground,
            title: normalStateColors.title,
            border: normalStateColors.border
        )
        self.selectedStateColors = selectedStateColors
    }

    // MARK: - Static Button Styles

    static let secondaryTextButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundSecondaryEnabled },
            title: ButtonColors.textSecondaryEnabled,
            border: ButtonColors.borderSecondaryEnabled
        ),
        highlightedStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundSecondaryHighlighted },
            title: ButtonColors.textSecondaryEnabled,
            border: ButtonColors.borderSecondaryHighlighted
        )
    )

    static let secondaryTextButtonStyleInConversationView = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundSecondaryInConversationViewEnabled },
            title: ButtonColors.textSecondaryEnabled,
            border: ButtonColors.borderSecondaryEnabled
        ),
        highlightedStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundSecondaryHighlighted },
            title: ButtonColors.textSecondaryEnabled,
            border: ButtonColors.borderSecondaryHighlighted
        )
    )

    static let accentColorTextButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { UIColor.accent() },
            title: ButtonColors.textPrimaryEnabled
        ),
        highlightedBackground: { UIColor.accentDarken }
    )

    static let addParticipantsButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { UIColor.accent() },
            title: SemanticColors.Label.textDefaultWhite
        ),
        highlightedBackground: { UIColor.accentDarken }
    )

    static let addParticipantsDisabledButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundPrimaryDisabled },
            title: ButtonColors.textPrimaryDisabled
        ),
        highlightedStateColors: ButtonStateColors( // No dynamic background change, so use full init
            background: { ButtonColors.backgroundPrimaryDisabled },
            title: ButtonColors.textPrimaryDisabled
        )
    )

    static let primaryTextButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundPrimaryEnabled },
            title: ButtonColors.textPrimaryEnabled
        ),
        highlightedBackground: { ButtonColors.backgroundPrimaryHighlighted }
    )

    static let emptyTextButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { .clear },
            title: ButtonColors.textEmptyEnabled
        ),
        highlightedStateColors: ButtonStateColors( // No dynamic background change, so use full init
            background: { .clear },
            title: ButtonColors.textEmptyEnabled
        )
    )

    static let iconButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundInputBarItemEnabled },
            title: ButtonColors.textInputBarItemEnabled,
            border: ButtonColors.borderInputBarItemEnabled
        ),
        highlightedStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundInputBarItemHighlighted },
            title: ButtonColors.textInputBarItemHighlighted,
            border: ButtonColors.borderInputBarItemHighlighted
        ),
        selectedStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundInputBarItemHighlighted },
            title: ButtonColors.textInputBarItemHighlighted,
            border: ButtonColors.borderInputBarItemHighlighted
        )
    )

    static let scrollToBottomButtonStyle = ButtonStyle(
        normalStateColors: ButtonStateColors(
            background: { ButtonColors.backgroundScrollToBottonEnabled },
            title: SemanticColors.Icon.foregroundDefaultWhite
        ),
        highlightedBackground: { UIColor.accent() }
    )
}
