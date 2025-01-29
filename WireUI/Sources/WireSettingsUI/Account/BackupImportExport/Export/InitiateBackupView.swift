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

struct InitiateBackupView: View {

    @StateObject var viewModel: InitiateBackupViewModel

    var body: some View {

        Section(footer: Text(L10n.Localizable.Settings.ExportBackup.description)) {

            Button(L10n.Localizable.Settings.ExportBackup.action) {
                viewModel.requestBackupPassword()
            }

            .sheet(isPresented: $viewModel.isBackupProgressPresented) {
                let progress: CreatingBackupProgress = if let backupURL = viewModel.backupURL {
                    .finished(backupURL)
                } else {
                    .ongoing(viewModel.backupProgress ?? 0)
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

            .alert(
                "Save failed.",
                isPresented: $viewModel.isErrorAlertPresented,
                presenting: viewModel.backupError
            ) { details in
                Button(role: .destructive) {
                    // Handle the deletion.
                } label: {
                    Text("Delete \(details)")
                }
                Button("Retry") {
                    // Handle the retry action.
                }
            } message: { details in
                Text("details.error")
            }

        }
    }
}

#Preview {
    List {
        InitiateBackupView(viewModel: .init())
    }
    .listStyle(.grouped)
}
