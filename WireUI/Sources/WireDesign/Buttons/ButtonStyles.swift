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

public enum WireButtonStyle: String, CaseIterable {
    case primary
    case secondary
    case tertiary
    case link
}

enum ButtonState: CaseIterable {
    case enabled
    case disabled
}

struct WireButtonStyleModifier: ViewModifier {
    let wireButtonStyle: WireButtonStyle

    @ViewBuilder
    private func applyStyle(_ wireButtonStyle: WireButtonStyle, content: () -> some View) -> some View {
        switch wireButtonStyle {
        case .primary:
            content().buttonStyle(PrimaryButtonStyle())
        case .secondary:
            content().buttonStyle(SecondaryButtonStyle())
        case .tertiary:
            content().buttonStyle(TertiaryButtonStyle())
        case .link:
            content().buttonStyle(LinkButtonStyle())
        }
    }

    func body(content: Content) -> some View {
        applyStyle(wireButtonStyle, content: { content })
    }
}

public extension View {
    func wireButtonStyle(_ wireButtonStyle: WireButtonStyle) -> some View {
        modifier(WireButtonStyleModifier(wireButtonStyle: wireButtonStyle))
    }
}

// MARK: - Preview

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {

        ForEach(ButtonState.allCases, id: \.self) { state in
            Group {
                ForEach(WireButtonStyle.allCases, id: \.rawValue) { style in
                    Button(action: {}, label: {
                        Text(style.rawValue)
                    })
                    .wireButtonStyle(style)
                    .padding()
                    .previewLayout(.sizeThatFits)
                    .previewDisplayName("\(style.rawValue) - \(state)")
                }
            }
            .disabled(state == .disabled)
        }
    }
}
