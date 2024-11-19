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

struct TertiaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) var isFocused

    typealias Theme = ColorTheme.Buttons.Tertiary
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = colors(for: configuration.isPressed, enabled: isEnabled)
        configuration.label
            .padding()
            .underline(color: colors.underline)
            .frame(maxWidth: .infinity)
            .background(colors.background)
            .foregroundStyle(colors.foreground)
            .overlay {
                if let borderColor = colors.border {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 1)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
    }
    
    func colors(for pressed: Bool, enabled: Bool) -> (underline: Color, background: Color, foreground: Color, border: Color?) {
        switch (enabled, pressed) {
        case (false, _):
            return (
                underline: Theme.onDisabled.color,
                background: Theme.disabled.color,
                foreground: Theme.onDisabled.color,
                border: nil
            )
        case (_, false):
            return (
                underline: Theme.onEnabled.color,
                background: Theme.enabled.color,
                foreground: Theme.onEnabled.color,
                border: nil
            )
        case (_, true):
            return (
                underline: Theme.onSelected.color,
                background: Theme.selected.color,
                foreground: Theme.onSelected.color,
                border: Theme.selectedOutline.color
            )
        }
    }
}
