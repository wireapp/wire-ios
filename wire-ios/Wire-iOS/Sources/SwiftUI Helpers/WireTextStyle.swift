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
import SwiftUI

enum WireTextStyle {

    case h1
    case h2
    case h3
    case h4
    case h5
    case body1
    case body2
    case body3
    case subline1
    case link
    case buttonSmall
    case buttonBig

}

extension Text {

    @ViewBuilder
    func textStyle(_ textStyle: WireTextStyle) -> some View {
        switch textStyle {
        case .h1:
            font(.title3)
        case .h2:
            font(.title3).bold()
        case .h3:
            font(.headline)
        case .h4:
            font(.subheadline)
        case .h5:
            font(.footnote)
        case .body1:
            font(.body)
        case .body2:
            font(.callout).fontWeight(.semibold)
        case .body3:
            font(.callout).bold()
        case .subline1:
            font(.caption)
        case .link:
            font(.body).underline()
        case .buttonSmall:
            fatalError("not implemented")
        case .buttonBig:
            font(.title3).fontWeight(.semibold)
        }
    }

}

