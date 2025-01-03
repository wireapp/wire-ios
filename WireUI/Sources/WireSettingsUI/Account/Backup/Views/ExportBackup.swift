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

public struct ExportBackup: View {

    @Environment(\.dismiss) private var dismiss
    private let onAction: (String) -> Void

    public init(onAction: @escaping (String) -> Void) {
        self.onAction = onAction
    }

    public var body: some View {
        SetBackupPasswordView(onAction: onAction)
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text("setBackupPassword.title",
                     tableName: "Localizable",
                     bundle: .module)
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

    private let onAction: (String) -> Void

    init(onAction: @escaping (String) -> Void) {
        self.onAction = onAction
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("setBackupPassword.description", tableName: "Localizable", bundle: .module)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

            PasswordFieldView(
                password: $password,
                isPasswordValid: isPasswordValid(),
                isPasswordVisible: $isPasswordVisible)

            Spacer()

            Button(
                action: {
                    onAction(password)
                    dismiss()
                },
                label: {
                    Text("setBackupPassword.button", tableName: "Localizable", bundle: .module)
                }
            )
            .wireButtonStyle(.primary)
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    // TODO: remove it
    private func isPasswordValid() -> Bool {
        guard !password.isEmpty else {
            return true
        }
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*()_+{}:<>?]).{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
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
                Text("setBackupPassword.button", tableName: "Localizable", bundle: .module)
            }
        )
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                ExportBackup(onAction: {_ in })
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.medium, .large])
        }
    }
}
