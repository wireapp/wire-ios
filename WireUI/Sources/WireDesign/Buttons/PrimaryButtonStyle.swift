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

struct PrimaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) var isFocused

    typealias PrimaryTheme = ColorTheme.Buttons.Primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isEnabled ? PrimaryTheme.enabled.color : PrimaryTheme.disabled.color)
            .foregroundStyle(isEnabled ? PrimaryTheme.onEnabled.color : PrimaryTheme.onDisabled.color)
            .wireTextStyle(.buttonBig)
            .clipShape(.rect(cornerRadius: 16))
    }

}
