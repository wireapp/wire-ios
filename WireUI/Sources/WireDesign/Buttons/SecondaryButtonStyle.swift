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

struct SecondaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) var isFocused

    typealias Theme = ColorTheme.Buttons.Secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? Theme.enabled.color : Theme.disabled.color)
            .foregroundStyle(isEnabled ? Theme.onEnabled.color : Theme.onDisabled.color)
            .wireTextStyle(.buttonBig)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEnabled ? Theme.enabledOutline.color : Theme.disabledOutline.color, lineWidth: 1)
            }
            .clipShape(.rect(cornerRadius: 16))
    }
}
