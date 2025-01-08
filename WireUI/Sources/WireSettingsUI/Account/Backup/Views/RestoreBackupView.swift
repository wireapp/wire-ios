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
    private let importBackup: (String) -> Void
    //private let importBackup1: (String) -> Void

    public init(
        importBackup: @escaping (String) -> Void
    ) {
        self.importBackup = importBackup
    }

    public var body: some View {
        PpasswordBackupView(importBackup: importBackup)
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(
                Text(L10n.RestoreFromBackup.title)
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

    private let importBackup: (String) -> Void

    init(importBackup: @escaping (String) -> Void) {
        self.importBackup = importBackup
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.RestoreFromBackup.description)
                .font(.textStyle(.body1))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            PasswordFieldView(
                password: $password,
                isPasswordVisible: $isPasswordVisible,
                title: Text(L10n.RestoreFromBackup.EnterPassword.title),
                passwordRules: nil
            )
            Spacer()

            Button(
                action: {
                    importBackup(password)
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
