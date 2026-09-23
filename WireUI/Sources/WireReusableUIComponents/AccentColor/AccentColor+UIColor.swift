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

import SwiftUI
import WireDesign
import WireFoundation

public extension AccentColor {

    var uiColor: UIColor {
        switch self {
        case .blue:
            SemanticColors.Accent.blue
        case .green:
            SemanticColors.Accent.green
        case .red:
            SemanticColors.Accent.red
        case .amber:
            SemanticColors.Accent.amber
        case .turquoise:
            SemanticColors.Accent.turquoise
        case .purple:
            SemanticColors.Accent.purple
        }
    }

    var secondaryUIColor: UIColor {
        switch self {
        case .blue:
            SemanticColors.Accent.Secondary.blue
        case .green:
            SemanticColors.Accent.Secondary.green
        case .red:
            SemanticColors.Accent.Secondary.red
        case .amber:
            SemanticColors.Accent.Secondary.amber
        case .turquoise:
            SemanticColors.Accent.Secondary.turquoise
        case .purple:
            SemanticColors.Accent.Secondary.purple
        }
    }

}

#Preview {
    VStack {
        ForEach(AccentColor.allCases, id: \.self) { accentColor in
            Color(uiColor: accentColor.uiColor)
        }
    }
}
