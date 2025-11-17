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

struct LinkButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    typealias Theme = ColorTheme.Buttons.Link

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .underline()
            .padding(8)
            .foregroundStyle(foregroundColor(for: isEnabled, and: isFocused))
            .font(for: .body1)
    }
}

private func foregroundColor(for isEnabled: Bool, and isFocused: Bool) -> Color {
    switch (isEnabled, isFocused) {
    case (false, _):
        ColorTheme.Buttons.Link.onDisabled.color
    case (true, true):
        ColorTheme.Buttons.Link.onFocus.color
    case (true, false):
        ColorTheme.Buttons.Link.onEnabled.color
    }
}
