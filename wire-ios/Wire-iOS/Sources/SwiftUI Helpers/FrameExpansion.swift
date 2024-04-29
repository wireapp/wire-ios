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

/// A view modifier to expand the frame to fit its parent container along a particular axis.

struct FrameExpansion: ViewModifier {

    let axis: Axis

    func body(content: Content) -> some View {
        switch axis {
        case .horizontal:
            return content.frame(maxWidth: .infinity)

        case .vertical:
            return content.frame(maxHeight: .infinity)
        }
    }

    enum Axis {

        case horizontal
        case vertical

    }

}

extension View {

    /// Expand the view to fit its parent contain along the given axis.

    func expandToFill(axis: FrameExpansion.Axis) -> some View {
        modifier(FrameExpansion(axis: axis))
    }

}
