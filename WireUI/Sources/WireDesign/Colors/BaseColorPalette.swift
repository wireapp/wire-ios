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

public enum BaseColorPalette {
    public enum LightUI {
        public enum MainColor {
            public static let blue500 = UIColor(resource: .blue500Light)
            public static let green500 = UIColor(resource: .green500Light)
            public static let petrol500 = UIColor(resource: .turquoise500Light)
            public static let purple500 = UIColor(resource: .purple500Light)
            public static let red500 = UIColor(resource: .red500Light)
            public static let amber500 = UIColor(resource: .amber500Light)
        }

        public enum MainColorShade {
            public static let blue50 = UIColor(resource: .blue50Light)
            public static let blue100 = UIColor(resource: .blue100Light)
            public static let blue200 = UIColor(resource: .blue200Light)
            public static let blue300 = UIColor(resource: .blue300Light)
            public static let blue400 = UIColor(resource: .blue400Light)
            public static let blue500 = UIColor(resource: .blue500Light)
            public static let blue600 = UIColor(resource: .blue600Light)
            public static let blue700 = UIColor(resource: .blue700Light)
            public static let blue800 = UIColor(resource: .blue800Light)
            public static let blue900 = UIColor(resource: .blue900Light)
        }
    }

    public enum DarkUI {
        public enum MainColor {
            public static let blue500 = UIColor(resource: .blue500Dark)
            public static let green500 = UIColor(resource: .green500Dark)
            public static let petrol500 = UIColor(resource: .turquoise500Dark)
            public static let purple500 = UIColor(resource: .purple500Dark)
            public static let red500 = UIColor(resource: .red500Dark)
            public static let amber500 = UIColor(resource: .amber500Dark)
        }

        public enum MainColorShade {
            public static let blue50 = UIColor(resource: .blue50Dark)
            public static let blue100 = UIColor(resource: .blue100Dark)
            public static let blue200 = UIColor(resource: .blue200Dark)
            public static let blue300 = UIColor(resource: .blue300Dark)
            public static let blue400 = UIColor(resource: .blue400Dark)
            public static let blue500 = UIColor(resource: .blue500Dark)
            public static let blue600 = UIColor(resource: .blue600Dark)
            public static let blue700 = UIColor(resource: .blue700Dark)
            public static let blue800 = UIColor(resource: .blue800Dark)
            public static let blue900 = UIColor(resource: .blue900Dark)
        }
    }

    public enum Neutrals {
        public static let white = UIColor.white
        public static let black = UIColor.black
    }

    public enum Grays {
        public static let gray10 = UIColor(resource: .gray10)
        public static let gray20 = UIColor(resource: .gray20)
        public static let gray30 = UIColor(resource: .gray30)
        public static let gray40 = UIColor(resource: .gray40)
        public static let gray50 = UIColor(resource: .gray50)
        public static let gray60 = UIColor(resource: .gray60)
        public static let gray70 = UIColor(resource: .gray70)
        public static let gray80 = UIColor(resource: .gray80)
        public static let gray90 = UIColor(resource: .gray90)
        public static let gray95 = UIColor(resource: .gray95)
        public static let gray100 = UIColor(resource: .gray100)
    }
}
