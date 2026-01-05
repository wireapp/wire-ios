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
import WireFoundation

public enum ColorTheme {

    public enum Base {

        public static func primary(_ accentColor: WireAccentColor) -> UIColor {
            switch accentColor {
            case .blue:
                UIColor(light: .blue500Light, dark: .blue500Dark)
            case .green:
                UIColor(light: .green500Light, dark: .green500Dark)
            case .red:
                UIColor(light: .red500Light, dark: .red500Dark)
            case .amber:
                UIColor(light: .amber500Light, dark: .amber500Dark)
            case .turquoise:
                UIColor(light: .turquoise500Light, dark: .turquoise500Dark)
            case .purple:
                UIColor(light: .purple500Light, dark: .purple500Dark)
            }
        }

        public static let onPrimary = UIColor(light: .white, dark: .black)

        public static func primaryVariant(_ accentColor: WireAccentColor) -> UIColor {
            switch accentColor {
            case .blue:
                UIColor(light: .blue50Light, dark: .blue800Dark)
            case .green:
                UIColor(light: .green50Light, dark: .green800Dark)
            case .red:
                UIColor(light: .red50Light, dark: .red800Dark)
            case .amber:
                UIColor(light: .amber50Light, dark: .amber800Dark)
            case .turquoise:
                UIColor(light: .turquoise50Light, dark: .turquoise800Dark)
            case .purple:
                UIColor(light: .purple50Light, dark: .purple800Dark)
            }
        }

        public static let onPrimaryVariant = UIColor(light: .blue500Light, dark: .blue300Dark)

        public static let error = UIColor(light: .red500Light, dark: .red500Dark)
        public static let onError = UIColor(light: .white, dark: .black)

        public static let warning = UIColor(light: .amber500Light, dark: .amber500Dark)
        public static let onWarning = UIColor(light: .white, dark: .black)

        public static let positive = UIColor(light: .green500Light, dark: .green500Dark)
        public static let onPositive = UIColor(light: .white, dark: .black)
        public static let onSuccess = UIColor(light: .white, dark: .black)

        public static let highlight = UIColor(light: .amber200Dark, dark: .amber300Dark)
        public static let onHighlight = UIColor(light: .black, dark: .black)

        public static let secondaryText = UIColor(light: .gray70, dark: .gray60)

        public static let requiredField = UIColor(light: .red500Light, dark: .red500Dark)

        public static let labelTitle = UIColor(light: .gray80, dark: .gray50)
        public static let onDisabled = UIColor(light: .gray80, dark: .gray50)
    }

    public enum Backgrounds {

        public static let background = UIColor(light: .gray20, dark: .gray100)
        public static let onBackground = UIColor(light: .black, dark: .white)

        public static let backgroundVariant = UIColor(light: .gray10, dark: .gray95)
        public static let onBackgroundVariant = UIColor(light: .black, dark: .white)

        public static let surface = UIColor(light: .white, dark: .gray95)
        public static let onSurface = UIColor(light: .black, dark: .white)

        public static let surfaceVariant = UIColor(light: .white, dark: .gray90)
        public static let onSurfaceVariant = UIColor(light: .black, dark: .white)

        public static let inverted = UIColor(light: .black, dark: .white)
        public static let onInverted = UIColor(light: .white, dark: .black)

        public static let onTransparentDark = UIColor(light: .white, dark: .white)
    }

    public enum Banners {
        public static let background = Base.primaryVariant
        public static let border = Base.primary
    }

    public enum Buttons {

        public enum Primary {

            public static let enabled = UIColor(light: .blue500Light, dark: .blue500Dark)
            static let onEnabled = UIColor(light: .white, dark: .black)

            static let disabled = UIColor(light: .gray50, dark: .gray80)
            static let onDisabled = UIColor(light: .gray80, dark: .gray50)

            static let focus = UIColor(light: .blue700Light, dark: .blue400Dark)
            static let onFocus = UIColor(light: .white, dark: .black)

            static let selected = UIColor(light: .blue700Light, dark: .blue400Dark)
            static let onSelected = UIColor(light: .white, dark: .black)
        }

        public enum Secondary {

            public static let enabled = UIColor(light: .white, dark: .gray90)
            public static let onEnabled = UIColor(light: .black, dark: .white)
            public static let enabledOutline = UIColor(light: .gray40, dark: .gray90)

            public static let disabled = UIColor(light: .gray20, dark: .gray95)
            public static let onDisabled = UIColor(light: .gray70, dark: .gray50)
            public static let disabledOutline = UIColor(light: .gray40, dark: .gray95)

            static let focus = UIColor(light: .gray30, dark: .blue800Dark)
            static let onFocus = UIColor(light: .black, dark: .white)
            static let focusOutline = UIColor(light: .blue500Light, dark: .blue500Dark)

            static let selected = UIColor(light: .blue50Light, dark: .blue800Dark)
            static let onSelected = UIColor(light: .blue500Light, dark: .white)
            static let selectedOutline = UIColor(light: .blue300Light, dark: .blue800Dark)
        }

        enum Tertiary {

            static let enabled = UIColor(light: .white, dark: .gray90)
            public static let onEnabled = UIColor(light: .black, dark: .white)
            static let enabledOutline = UIColor(light: .gray40, dark: .gray100)

            static let disabled = UIColor(light: .gray20, dark: .gray95)
            static let onDisabled = UIColor(light: .gray70, dark: .gray50)
            static let disabledOutline = UIColor(light: .gray40, dark: .gray95)

            static let focus = UIColor(light: .gray30, dark: .blue800Dark)
            static let onFocus = UIColor(light: .black, dark: .white)
            static let focusOutline = UIColor(light: .blue500Light, dark: .blue500Dark)

            static let selected = UIColor(light: .blue50Light, dark: .blue800Dark)
            static let onSelected = UIColor(light: .blue500Light, dark: .white)
            static let selectedOutline = UIColor(light: .blue300Light, dark: .blue800Dark)
        }

        enum Link {
            public static let onEnabled = Backgrounds.onSurface

            static let onDisabled = Base.secondaryText

            static let onFocus = Base.primary

            static let onSelected = Base.primary
        }
    }

    public enum Checkbox {
        public static let enabled = UIColor(light: .gray50, dark: .gray80)
        public static let selected = UIColor(light: .blue500Light, dark: .blue500Dark)
    }

    public enum Strokes {

        public static let outline = UIColor(light: .gray40, dark: .gray90)
        public static let disabledOutline = UIColor(light: .gray50, dark: .gray80)
        public static let dividersOutlineVariant = UIColor(light: .gray20, dark: .gray100)
    }

    public enum Classified {

        public static let positive = UIColor(light: .green50Light, dark: .green900Dark)
        public static let onPositive = UIColor(light: .green500Light, dark: .green500Dark)

        public static let negative = UIColor(light: .red600Light, dark: .red500Dark)
        public static let onNegative = UIColor(light: .white, dark: .black)
    }

    public enum Backdrop {
        public static let background = UIColor.black.withAlphaComponent(0.55)
    }

    public enum NotificationBadge {
        public static let fill = ColorTheme.Base.error
    }
}

private extension UIColor {

    convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

public extension UIColor {
    var color: Color {
        Color(self)
    }
}
