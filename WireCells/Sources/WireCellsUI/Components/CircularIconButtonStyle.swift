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
import WireDesign

struct CircularIconButtonStyle: ButtonStyle {
    private enum Constants {
        static let backgroundColor: Color = Color(ColorTheme.Backgrounds.onSurface)
        static let iconColor: Color = Color(ColorTheme.Buttons.Secondary.enabled)
        static let strokeColor: Color = Color(ColorTheme.Buttons.Secondary.enabledOutline)
        static let strokeWidth: CGFloat = 1
    }

    let padding: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .symbolRenderingMode(.palette)
            .foregroundStyle(Constants.backgroundColor, Constants.iconColor)
            .overlay(
                Circle().strokeBorder(Constants.strokeColor, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.5 : 1.0)
    }
}

#Preview {
    Button(action: {
        print("Tapped")
    }, label: {
        Image(systemName: "xmark.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    })
    .buttonStyle(CircularIconButtonStyle(padding: 0))
    .background(Color.green)
}
