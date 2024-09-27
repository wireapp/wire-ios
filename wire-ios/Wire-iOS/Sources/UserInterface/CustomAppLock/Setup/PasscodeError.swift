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

enum PasscodeError: CaseIterable {
    case tooShort
    case noLowercaseChar
    case noUppercaseChar
    case noNumber
    case noSpecialChar

    // MARK: Internal

    var message: String {
        switch self {
        case .tooShort:
            L10n.Localizable.CreatePasscode.Validation.tooShort
        case .noLowercaseChar:
            L10n.Localizable.CreatePasscode.Validation.noLowercaseChar
        case .noUppercaseChar:
            L10n.Localizable.CreatePasscode.Validation.noUppercaseChar
        case .noSpecialChar:
            L10n.Localizable.CreatePasscode.Validation.noSpecialChar
        case .noNumber:
            L10n.Localizable.CreatePasscode.Validation.noNumber
        }
    }

    var descriptionWithInvalidIcon: NSAttributedString {
        description(icon: .circleCross, color: SemanticColors.Icon.backgroundPasswordRuleCheck, font: .smallRegularFont)
    }

    var descriptionWithPassedIcon: NSAttributedString {
        description(icon: .circleTick, color: SemanticColors.Icon.backgroundJoinCall, font: .smallSemiboldFont)
    }

    // MARK: Private

    private func description(icon: StyleKitIcon, color: UIColor, font: UIFont) -> NSAttributedString {
        let textAttachment = NSTextAttachment.textAttachment(
            for: icon,
            with: color,
            iconSize: StyleKitIcon.Size.CreatePasscode.iconSize,
            verticalCorrection: -1,
            insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        )

        let attributedString = NSAttributedString(string: message) && font

        return NSAttributedString(attachment: textAttachment) + attributedString
    }
}
