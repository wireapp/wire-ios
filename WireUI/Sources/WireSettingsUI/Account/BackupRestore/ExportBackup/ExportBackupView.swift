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

/// A view that allows to export the backup.

struct ExportBackupView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private(set) var viewModel: ExportBackupViewModel
    @State private var isScrollDisabled: Bool = true

    var body: some View {
        NavigationStack {
            setBackupPasswordView
                .background(Color.viewBackground)
                .scrollContentBackground(.hidden)
                .navigationTitle(Text(L10n.Localizable.ExportBackup.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton { dismiss() }
                            .accessibilityLabel(Text(L10n.Accessibility.SetBackupPassword.Close.label))
                    }
                }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var setBackupPasswordView: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
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
                    }
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.onAppear {
                                isScrollDisabled = contentGeometry.size.height <= geometry.size.height
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
                .scrollDisabled(isScrollDisabled)

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
        }
    }

}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Export Backup sheet") {
    ExportBackupPreview()
}
