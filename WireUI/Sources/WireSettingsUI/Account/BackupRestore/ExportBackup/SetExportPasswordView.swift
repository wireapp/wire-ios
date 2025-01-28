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

typealias ExportBackupView = SetExportPasswordView

/// A view that allows to export the backup.

struct SetExportPasswordView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private(set) var viewModel: SetExportPasswordViewModel

    var body: some View {
        setBackupPasswordView
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(Text(L10n.Localizable.ExportBackup.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(
                        action: { dismiss() },
                        accessibilityLabel: L10n.Accessibility.SetBackupPassword.Close.label
                    )
                }
            }
    }

    @ViewBuilder
    private var setBackupPasswordView: some View {
        VStack {
//            let scrollView = ScrollView {
//                VStack(spacing: 20) {
                    Text(L10n.Localizable.ExportBackup.description)
                        .wireTextStyle(.body1)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    PasswordFieldView(
                        password: $viewModel.password,
                        isPasswordVisible: $viewModel.isPasswordVisible,
                        isPasswordValid: viewModel.isPasswordValid,
                        passwordRules: Text(viewModel.localizedPasswordRules)
                    )
                    .background(Color.red)
//                }
//                //                    .frame(maxWidth: .infinity)
//            }
//            if #available(iOS 16.4, *) {
//                scrollView
//                    .scrollBounceBehavior(.basedOnSize)
//            } else {
//                scrollView
//            }

            Spacer()

            Button {
                dismiss()
                viewModel.triggerExport()
            } label: {
                Text(L10n.Localizable.ExportBackup.button)
            }
            .disabled(!viewModel.isPasswordValid)
            .wireButtonStyle(.primary)
            .padding()
        }
        .background(Color.green)
    }
}

// MARK: - Previews

#Preview("Set Export Backup Password") {
    SetExportPasswordPreview()
}
