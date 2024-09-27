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

// swiftlint:disable:next todo_requires_jira_link
// TODO: - [AGIS] Clean this up
enum CallActionAppearance: Equatable {
    case light
    case dark(blurred: Bool)

    // MARK: Internal

    var showBlur: Bool {
        switch self {
        case .light: false
        case let .dark(blurred: blurred): blurred
        }
    }

    var backgroundColorNormal: UIColor {
        switch self {
        case .light: UIColor.lightGraphite.withAlphaComponent(0.08)
        case .dark: UIColor.white.withAlphaComponent(0.24)
        }
    }

    var backgroundColorSelected: UIColor {
        switch self {
        case .light: UIColor.from(scheme: .iconNormal, variant: .light)
        case .dark: UIColor.from(scheme: .iconNormal, variant: .dark)
        }
    }

    var backgroundColorSelectedAndHighlighted: UIColor {
        switch self {
        case .light: UIColor.black.withAlphaComponent(0.16)
        case .dark: UIColor.white.withAlphaComponent(0.4)
        }
    }

    var iconColorNormal: UIColor {
        switch self {
        case .light: UIColor.from(scheme: .iconNormal, variant: .light)
        case .dark: UIColor.from(scheme: .iconNormal, variant: .dark)
        }
    }

    var iconColorSelected: UIColor {
        switch self {
        case .light: UIColor.from(scheme: .iconNormal, variant: .dark)
        case .dark: UIColor.from(scheme: .iconNormal, variant: .light)
        }
    }
}
