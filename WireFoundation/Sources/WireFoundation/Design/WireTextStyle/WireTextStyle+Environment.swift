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

import SwiftUI

/// Used for getting the text style mapping from the environment.
private struct WireTextStyleView<Content: View>: View {

    @Environment(\.wireTextStyleMapping) private var wireTextStyleMapping

    let textStyle: WireTextStyle?
    @ViewBuilder let content: () -> Content

    var body: some View {

        // do nothing if the mapping has not been set into the environment
        if let wireTextStyleMapping {
            let font = textStyle.map { textStyle in
                wireTextStyleMapping.font(for: textStyle)
            }
            content()
                .font(font)

        } else {
            content()
        }
    }
}

public extension View {
    func wireTextStyle(_ textStyle: WireTextStyle?) -> some View {
        WireTextStyleView(textStyle: textStyle) {
            self
        }
    }
}
