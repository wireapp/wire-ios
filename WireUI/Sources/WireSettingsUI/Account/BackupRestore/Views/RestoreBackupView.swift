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
import WireReusableUIComponents

struct RestoreBackupView: View {

    @Environment(\.dismiss) private var dismiss

    // TODO: move to view model?
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var contentFits: Bool = true

    private let importBackup: (String) -> Void

    var body: some View {
        passwordBackupView
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text(L10n.Localizable.RestoreFromBackup.title)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(action: didTapClose)
                        .accessibilityLabel(Text(L10n.Accessibility.RestoreBackup.Close.label))
                }
            }
    }

    private func didTapClose() {
        dismiss()
    }

    @ViewBuilder private var passwordBackupView: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(L10n.Localizable.RestoreFromBackup.description)
                            .wireTextStyle(.body1)
                            .foregroundStyle(Color.primaryText)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        enterPasswordFieldView
                    }
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.onAppear {
                                contentFits = contentGeometry.size.height <= geometry.size.height
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
                .scrollDisabled(contentFits)

                Spacer()

                Button(
                    action: {
                        importBackup(password)
                        dismiss()
                    },
                    label: {
                        Text(L10n.Localizable.RestoreFromBackup.button)
                    }
                )
                .wireButtonStyle(.primary)
                .padding()
            }
        }
    }

    @ViewBuilder
    private var enterPasswordFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Localizable.RestoreFromBackup.EnterPassword.title)
                .font(.subheadline)
                .foregroundColor(password.isEmpty ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.primary.color)

            ZStack {
                if isPasswordVisible {
                    TextField(
                        L10n.Localizable.ExportBackup.SetBackupPassword.placeholder,
                        text: $password
                    )
                    .wireTextStyle(.body1)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField(
                        L10n.Localizable.ExportBackup.SetBackupPassword.placeholder,
                        text: $password
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Spacer()
                    Button(action: {
                        isPasswordVisible.toggle()
                    }, label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .foregroundColor(.gray)
                    })
                    .padding(.trailing, 10)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(
                        password.isEmpty ? ColorTheme.Base.secondaryText.color : ColorTheme.Base.primary.color,
                        lineWidth: password.isEmpty ? 0 : 1
                    )
            )

        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Export Backup sheet") {
    RestoreBackupPreview()
}
