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
import WireFoundation

public struct LabeledTextField: View {
    @Environment(\.isEnabled) private var isEnabled

    private let isMandatory: Bool
    private let placeholder: String?
    private let title: String?

    @FocusState var isFocused: Bool
    @Binding private var string: String

    public init(
        isMandatory: Bool = false,
        placeholder: String?,
        title: String?,
        string: Binding<String>
    ) {
        self.isMandatory = isMandatory
        self.placeholder = placeholder
        self.title = title
        self._string = string
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                (
                    isMandatory ? (
                        Text(title) +
                            Text(verbatim: " *")
                            .foregroundColor(ColorTheme.Base.requiredField.color)
                    ) : Text(title)
                )
                .foregroundStyle(titleColor(isEnabled: isEnabled, isFocused: isFocused))
                .wireTextStyle(.subline1)
            }
            HStack(spacing: 0) {
                TextField(placeholder ?? "", text: $string)
                    .wireTextStyle(.body1)
                    .focused($isFocused)
                    .foregroundStyle(labelColor(isEnabled: isEnabled))
                    .padding(.vertical, 12)
                if !string.isEmpty, isEnabled {
                    Button(action: {
                        string = ""
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.black)
                            .frame(width: 16, height: 16)
                            .padding(19)
                    })
                }
            }
            .padding(.leading, 16)
            .background {
                if #available(iOS 17.0, *) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(labelBackgroundColor(isEnabled: isEnabled))
                        .stroke(labelBorderColor(isEnabled: isEnabled, isFocused: isFocused), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(labelBorderColor(isEnabled: isEnabled, isFocused: isFocused), lineWidth: 1)
                        .background(labelBackgroundColor(isEnabled: isEnabled))
                        .cornerRadius(12)
                }
            }
        }
    }
}

private func titleColor(isEnabled: Bool, isFocused: Bool) -> Color {
    if isEnabled, isFocused {
        return ColorTheme.Base.onPrimaryVariant.color
    }
    if isEnabled {
        return ColorTheme.Base.labelTitle.color
    }
    return ColorTheme.Base.labelTitle.color
}

private func labelColor(isEnabled: Bool) -> Color {
    if isEnabled {
        return .primaryText
    }
    return ColorTheme.Base.onDisabled.color
}

private func labelBackgroundColor(isEnabled: Bool) -> Color {
    if isEnabled {
        return .clear
    }
    return ColorTheme.Backgrounds.background.color
}

private func labelBorderColor(isEnabled: Bool, isFocused: Bool) -> Color {
    if isEnabled, isFocused {
        return ColorTheme.Base.onPrimaryVariant.color
    }
    if isEnabled {
        return ColorTheme.Strokes.outline.color
    }
    return ColorTheme.Strokes.outline.color
}

#Preview {
    LabeledTextField(
        isMandatory: false,
        placeholder: nil,
        title: nil,
        string: .constant("")
    )
    .padding()
    LabeledTextField(
        isMandatory: false,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("")
    )
    .padding()
    LabeledTextField(
        isMandatory: true,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("")
    )
    .padding()
    LabeledTextField(
        isMandatory: true,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("Lorem ipsum dolor sit amet, consectetur [...]")
    )
    .padding()
    LabeledTextField(
        isMandatory: true,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("Lorem ipsum dolor sit amet, consectetur [...]")
    )
    .padding()
    .disabled(true)
}
