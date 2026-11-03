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
import WireFoundation

struct SecondaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.wireAccentColor) private var wireAccentColor
    @Environment(\.isFocused) var isFocused

    typealias Theme = ColorTheme.Buttons.Secondary

    private let useAccentColor: Bool

    init(useAccentColor: Bool = false) {
        self.useAccentColor = useAccentColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Theme.enabled.color : Theme.disabled.color)
            .foregroundStyle(isEnabled ? enabledForegroundColor : Theme.onDisabled.color)
            .font(for: .buttonBig)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEnabled ? enabledOutlineColor : Theme.disabledOutline.color, lineWidth: 1)
            }
            .clipShape(.rect(cornerRadius: 16))
    }

    private var enabledForegroundColor: Color {
        useAccentColor ? ColorTheme.Base.primary(wireAccentColor).color : Theme.onEnabled.color
    }

    private var enabledOutlineColor: Color {
        useAccentColor ? ColorTheme.Base.primary(wireAccentColor).color : Theme.enabledOutline.color
    }
}
