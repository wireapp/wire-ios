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

public struct ExportBackupView: View {

    @Environment(\.dismiss) private var dismiss
    private let exportBackup: (String) -> Void
    private let passwordValidator: any BackupPasswordValidatorProtocol

    public init(
        passwordValidator: any BackupPasswordValidatorProtocol,
        exportBackup: @escaping (String) -> Void
    ) {
        self.exportBackup = exportBackup
        self.passwordValidator = passwordValidator
    }

    public var body: some View {
        SetBackupPasswordView(
            passwordValidator: passwordValidator,
            exportBackup: exportBackup)
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text(L10n.ExportBackup.title)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(
                        action: didTapClose,
                        accessibilityLabel: String(
                            localized: "setBackupPassword.close.label",
                            table: "Accessibility",
                            bundle: .module
                        )
                    )
                }
            }
    }

    private func didTapClose() {
        dismiss()
    }

}

private struct SetBackupPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false

    private let passwordValidator: any BackupPasswordValidatorProtocol
    private let exportBackup: (String) -> Void

    init(
        passwordValidator: any BackupPasswordValidatorProtocol,
        exportBackup: @escaping (String) -> Void
    ) {
        self.passwordValidator = passwordValidator
        self.exportBackup = exportBackup
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.ExportBackup.description)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

            PasswordFieldView(
                password: $password,
                isPasswordValid: passwordValidator.isValid(password: password),
                isPasswordVisible: $isPasswordVisible,
                passwordRules: Text(passwordValidator.localizedRulesDescription))

            Spacer()

            Button(
                action: {
                    exportBackup(password)
                    dismiss()
                },
                label: {
                    Text(L10n.ExportBackup.button)
                }
            )
            .wireButtonStyle(.primary)
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Export Backup sheet") {
    ExportBackupPreview()
}

private struct ExportBackupPreview: View {
    @State private var isPresented = true

    var body: some View {
        Button(
            action: {
                isPresented.toggle()
            },
            label: {
                Text(L10n.ExportBackup.button)
            }
        )
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                ExportBackupView(
                    passwordValidator: MockBackupPasswordValidator(),
                    exportBackup:  {_ in }
                )
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
    }
}
