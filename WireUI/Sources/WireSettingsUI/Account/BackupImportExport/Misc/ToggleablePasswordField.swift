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

struct ToggleablePasswordField: View {

    @Binding var password: String

    var titleColor: Color
    var borderColor: Color
    var focusOnAppear = true

    @State private var isPasswordVisible = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {

            if isPasswordVisible {
                TextField(text: $password) {
                    Text(L10n.Localizable.ImportBackup.EnterPassword.TextField.placeholder)
                        .font(.body)
                        .foregroundStyle(titleColor)
                }
                .focused($isFocused)
                .textContentType(.password)
                .autocapitalization(.none)
            } else {
                SecureField(text: $password) {
                    Text(L10n.Localizable.ImportBackup.EnterPassword.TextField.placeholder)
                        .font(.body)
                        .foregroundStyle(titleColor)
                }
                .focused($isFocused)
                .textContentType(.password)
            }

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                    .foregroundColor(Color(uiColor: ColorTheme.Backgrounds.onSurface))
            }

        }
        .padding()
        .background(Color(uiColor: ColorTheme.Backgrounds.surface))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
        .onAppear {
            if focusOnAppear {
                isFocused = true
            }
        }
    }
}

#Preview {
    ToggleablePasswordField(
        password: .constant(""),
        titleColor: Color(uiColor: BaseColorPalette.Neutrals.black),
        borderColor: Color(uiColor: BaseColorPalette.Neutrals.black)
    )
    .padding()
}
