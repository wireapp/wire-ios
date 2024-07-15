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

// The structure of this type corresponds to the Wire design system.

public enum ColorTheme {

    public enum Base {

        public static let primary = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let onPrimary = UIColor(light: .white, dark: .black)

        public static let primaryVariant = UIColor(light: .blue50Light, dark: .blue800Dark)
        public static let onPrimaryVariant = UIColor(light: .blue500Light, dark: .blue300Dark)

        public static let error = UIColor(light: .red500Light, dark: .red500Dark)
        public static let onError = UIColor(light: .white, dark: .black)

        public static let warning = UIColor(light: .amber500Light, dark: .amber500Dark)
        public static let onWarning = UIColor(light: .white, dark: .black)

        public static let positive = UIColor(light: .green500Light, dark: .green500Dark)
        public static let onSuccess = UIColor(light: .white, dark: .black)

        public static let highlight = UIColor(light: .amber200Dark, dark: .amber300Dark)
        public static let onHighlight = UIColor(light: .black, dark: .black)

        public static let secondaryText = UIColor(light: .gray70, dark: .gray60)
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
    }

    public enum Buttons {

        public enum Primary {

            public static let enabled = UIColor(light: .blue500Light, dark: .blue500Dark)
            public static let onEnabled = UIColor(light: .white, dark: .black)

            public static let disabled = UIColor(light: .gray50, dark: .gray80)
            public static let onDisabled = UIColor(light: .gray80, dark: .gray50)

            public static let focus = UIColor(light: .blue700Light, dark: .blue400Dark)
            public static let onFocus = UIColor(light: .white, dark: .black)

            public static let selected = UIColor(light: .blue700Light, dark: .blue400Dark)
            public static let onSelected = UIColor(light: .white, dark: .black)
        }

        public enum Secondary {

            public static let enabled = UIColor(light: .white, dark: .gray90)
            public static let onEnabled = UIColor(light: .black, dark: .white)
            public static let enabledOutline = UIColor(light: .gray40, dark: .gray90)

            public static let disabled = UIColor(light: .gray20, dark: .gray95)
            public static let onDisabled = UIColor(light: .gray70, dark: .gray50)
            public static let disabledOutline = UIColor(light: .gray40, dark: .gray95)

            public static let focus = UIColor(light: .gray30, dark: .blue800Dark)
            public static let onFocus = UIColor(light: .black, dark: .white)
            public static let focusOutline = UIColor(light: .blue500Light, dark: .blue500Dark)

            public static let selected = UIColor(light: .blue50Light, dark: .blue800Dark)
            public static let onSelected = UIColor(light: .blue500Light, dark: .white)
            public static let selectedOutline = UIColor(light: .blue300Light, dark: .blue800Dark)
        }

        public enum Tertiary {

            public static let enabled = UIColor.clear
            public static let onEnabled = UIColor(light: .black, dark: .white)

            public static let disabled = UIColor.clear
            public static let onDisabled = UIColor(light: .gray60, dark: .gray60)

            public static let focus = UIColor(light: .gray30, dark: .gray90)
            public static let onFocus = UIColor(light: .black, dark: .white)
            public static let focusOutline = UIColor(light: .blue500Light, dark: .blue500Dark)

            public static let selected = UIColor(light: .blue50Light, dark: .gray95)
            public static let onSelected = UIColor(light: .blue500Light, dark: .blue500Dark)
            public static let selectedOutline = UIColor(light: .blue300Light, dark: .gray90)
        }
    }

    public enum Strokes {

        public static let outline = UIColor(light: .gray40, dark: .gray90)
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
}

private extension UIColor {

    convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
