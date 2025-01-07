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
    private let backupPath: URL
    private let importBackup: (String, URL) -> Void

    public init(
        backupPath: URL,
        importBackup: @escaping (String, URL) -> Void
    ) {
        self.backupPath = backupPath
        self.importBackup = importBackup
    }

    public var body: some View {
        PpasswordBackupView(
            backupPath: backupPath, importBackup: importBackup)
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text("Enter password")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(
                        action: didTapClose,
                        accessibilityLabel: String(
                            localized: "restoreBackup.close.label",
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

private struct PpasswordBackupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false

    private let backupPath: URL
    private let importBackup: (String, URL) -> Void

    init(
        backupPath: URL,
        importBackup: @escaping (String, URL) -> Void
    ) {
        self.backupPath = backupPath
        self.importBackup = importBackup
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.RestoreFromBackup.title)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

//            PasswordFieldView(
//                password: $password,
//                isPasswordValid: passwordValidator.isValid(password: password),
//                isPasswordVisible: $isPasswordVisible,
//                passwordRules: Text(passwordValidator.localizedRulesDescription))

            Spacer()

            Button(
                action: {
                    importBackup(password, backupPath)
                    dismiss()
                },
                label: {
                    Text(L10n.RestoreFromBackup.button)
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
    RestoreBackupPreview()
}

private struct RestoreBackupPreview: View {
    @State private var isPresented = true

    var body: some View {
        Button(
            action: {
                isPresented.toggle()
            },
            label: {
                Text(L10n.RestoreFromBackup.button)
            }
        )
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                RestoreBackupView(
                    backupPath: URL(fileURLWithPath: ""),
                    importBackup:  { _, _ in }
                )
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
    }
}
