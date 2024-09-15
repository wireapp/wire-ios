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

// TODO: remove commented code
//private struct WireTextStyleKey: EnvironmentKey {
//    static let defaultValue: WireTextStyle? = .none
//}
//
//private extension EnvironmentValues {
//    var wireTextStyle: WireTextStyle? {
//        get { self[WireTextStyleKey.self] }
//        set { self[WireTextStyleKey.self] = newValue }
//    }
//}
//
//public extension View {
//    func wireTextStyle(_ textStyle: WireTextStyle?) -> some View {
//        environment(\.wireTextStyle, textStyle)
//    }
//}

/// Used for getting the text style mapping from the environment.
private struct WireTextStyleView<Content: View>: View {

    @Environment(\.wireTextStyleMapping) private var wireTextStyleMapping

    let textStyle: WireTextStyle?
    @ViewBuilder let content: () -> Content

    var body: some View {
        let font = textStyle.map { textStyle in
                wireTextStyleMapping.font(for: textStyle)
            }
        content()
            .font(font)
    }
}

public extension View {
    func wireTextStyle(_ textStyle: WireTextStyle?) -> some View {
        WireTextStyleView(textStyle: textStyle) {
            self
        }
    }
}
