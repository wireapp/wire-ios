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

struct PrimaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) var isFocused

    typealias PrimaryTheme = ColorTheme.Buttons.Primary
    
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? PrimaryTheme.enabled.color : PrimaryTheme.disabled.color)
                .foregroundStyle(isEnabled ? PrimaryTheme.onEnabled.color : PrimaryTheme.onDisabled.color)
               
                .clipShape(.rect(cornerRadius: 16))
        }
    

}

struct SecondaryButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) var isFocused

    typealias Theme = ColorTheme.Buttons.Secondary
    
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? Theme.enabled.color : Theme.disabled.color)
                .foregroundStyle(isEnabled ? Theme.onEnabled.color : Theme.onDisabled.color)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isEnabled ? Theme.enabledOutline.color: Theme.disabledOutline.color, lineWidth: 1)
                }
                .clipShape(.rect(cornerRadius: 16))
        }
}

//
//struct WireButtonStyle {
//    let underline: Color
//    let background: Color
//    let foreground: Color
//    let border: Color?
//}

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

enum WireButtonStyle: String, CaseIterable {
    case primary
    case secondary
    case tertiary
}

enum ButtonState: CaseIterable {
    case enabled
    case disabled
}

struct WireButtonStyleModifier: ViewModifier {
    let wireButtonStyle: WireButtonStyle
    
    
    @ViewBuilder private func applyStyle(_ wireButtonStyle: WireButtonStyle, content: () -> some View) -> some View {
        switch wireButtonStyle {
        case .primary:
            content().buttonStyle(PrimaryButtonStyle())
        case .secondary:
            content().buttonStyle(SecondaryButtonStyle())
        case .tertiary:
            content().buttonStyle(TertiaryButtonStyle())
        }
    }

    func body(content: Content) -> some View {
        applyStyle(wireButtonStyle, content: { content })
    }
}

extension View {
    func wireButtonStyle(_ wireButtonStyle: WireButtonStyle) -> some View {
        self.modifier(WireButtonStyleModifier(wireButtonStyle: wireButtonStyle))
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
