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

struct ExportBackupView: View {

    @StateObject var viewModel: ExportBackupViewModel

    var body: some View {

        Section(footer: Text(L10n.Localizable.Settings.ExportBackup.description)) {

            Button {
                viewModel.requestBackupPassword()
            } label: {
                Text(L10n.Localizable.Settings.ExportBackup.action)
                    .wireTextStyle(.body2)
                    .foregroundStyle(Color.primaryText)
            }

            .background( // Move alert to a background layer
                Color.clear.alert( // TODO: fix
                        "Save failed.",
                        isPresented: $viewModel.isErrorAlertPresented,
                        presenting: viewModel.backupError
                    ) { backupError in
                        Button(role: .destructive) {
                            // Handle the deletion.
                        } label: {
                            Text("Delete \(backupError)")
                        }
                        Button("Retry") {
                            // Handle the retry action.
                        }
                    } message: { backupError in
                        Text("details.error")
                    }
            )

            .sheet(isPresented: $viewModel.isCreatingBackupProgressPresented) {
                let progress: CreatingBackupProgressModel = if let backupURL = viewModel.backupURL {
                    .finished(backupURL)
                } else {
                    .ongoing(viewModel.backupProgress)
                }
                CreatingBackupProgressView(
                    progress: progress,
                    cancelAction: { viewModel.cancel() }
                )
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
                .sheet(isPresented: $viewModel.isSetBackupPasswordPresented) {
                    SetBackupPasswordView(
                        onProceed: { password in viewModel.createBackup(password: password) },
                        onCancel: { viewModel.cancel() }
                    )
                    .interactiveDismissDisabled()
                    .presentationDetents([.large])
                }
            }

        }
    }
}

#Preview {
    ExportBackupPreview()
}
