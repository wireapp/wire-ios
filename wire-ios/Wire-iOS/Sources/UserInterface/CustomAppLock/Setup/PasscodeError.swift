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

import Foundation
import UIKit
import WireCommonComponents

enum PasscodeError: CaseIterable {
    case tooShort
    case noLowercaseChar
    case noUppercaseChar
    case noNumber
    case noSpecialChar

    var message: String {
        switch self {
        case .tooShort:
            return L10n.Localizable.CreatePasscode.Validation.tooShort
        case .noLowercaseChar:
            return L10n.Localizable.CreatePasscode.Validation.noLowercaseChar
        case .noUppercaseChar:
            return L10n.Localizable.CreatePasscode.Validation.noUppercaseChar
        case .noSpecialChar:
            return L10n.Localizable.CreatePasscode.Validation.noSpecialChar
        case .noNumber:
            return L10n.Localizable.CreatePasscode.Validation.noNumber
        }

    }

    private func description(icon: StyleKitIcon, color: UIColor, font: UIFont) -> NSAttributedString {
        let textAttachment = NSTextAttachment.textAttachment(for: icon,
                                                             with: color,
                                                             iconSize: StyleKitIcon.Size.CreatePasscode.iconSize,
                                                             verticalCorrection: -1,
                                                             insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8))

        let attributedString: NSAttributedString = NSAttributedString(string: message) && font

        return NSAttributedString(attachment: textAttachment) + attributedString

    }

    var descriptionWithInvalidIcon: NSAttributedString {
        return description(icon: .circleCross, color: SemanticColors.Icon.backgroundPasswordRuleCheck, font: .smallRegularFont)
    }

    var descriptionWithPassedIcon: NSAttributedString {
        return description(icon: .circleTick, color: SemanticColors.Icon.backgroundJoinCall, font: .smallSemiboldFont)
    }
}
