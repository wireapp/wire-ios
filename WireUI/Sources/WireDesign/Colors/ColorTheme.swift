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

public enum ColorTheme {

    public enum Base {
        public static let primary = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let primaryVariant = UIColor(light: .blue50Light, dark: .blue800Dark)
        public static let error = UIColor(light: .red500Light, dark: .red500Dark)
        // TODO: continue, see Figma App Colors
    }

    public enum Strokes {
        public static let outline = UIColor(light: .gray40, dark: .gray90)
    }
}

extension UIColor {

    fileprivate convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
