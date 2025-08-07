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
        static let backgroundColor: Color = BaseColorPalette.Neutrals.white.color
        static let iconColor: Color = BaseColorPalette.Neutrals.black.color
        static let strokeColor: Color = BaseColorPalette.Grays.gray40.color
        static let strokeWidth: CGFloat = 1
    }

    let padding: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(Constants.backgroundColor)
            .overlay(Circle().stroke(Constants.strokeColor, lineWidth: Constants.strokeWidth).padding(padding))
            .background(Circle().fill(Constants.iconColor).padding(padding))
            // Optionally, apply a slight visual change when pressed
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

#Preview {
    Button(action: {
        print("Tapped")
    }, label: {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: 24))
            .buttonStyle(CircularIconButtonStyle(padding: 2))
    })
    .foregroundStyle(.white)
    .frame(width: 35, height: 35)
    .padding(20)
    .background(Color.gray)
}
