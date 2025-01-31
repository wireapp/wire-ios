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

struct ImportBackupView: View {

    @StateObject var viewModel: ImportBackupViewModel

    @State private var isFileImporterPresented = false

    var body: some View {
        Section(footer: Text(L10n.Localizable.Settings.RestoreFromBackup.description)) {

            Button {
                isFileImporterPresented = true
            } label: {
                Text(L10n.Localizable.Settings.RestoreFromBackup.action)
                    .font(.textStyle(.body2))
                    .foregroundStyle(Color.primaryText)
            }
            

            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: WireBackupUTIs
            ) { result in
                viewModel.pickedBackupFile(result: result)
            }

            .sheet(isPresented: $viewModel.isImportingBackupProgressPresented) {
                Text("progress \(viewModel.importProgress)")
//                let progress: CreatingBackupProgressModel = if let backupURL = viewModel.backupURL {
//                    .finished(backupURL)
//                } else {
//                    .ongoing(viewModel.backupProgress ?? 0)
//                }
//                CreatingBackupProgressView(
//                    progress: progress,
//                    cancelAction: { viewModel.cancel() }
//                )
//                .interactiveDismissDisabled()
//                .presentationDetents([.medium])
//                .sheet(isPresented: $viewModel.isSetBackupPasswordPresented) {
//                    SetBackupPasswordView(
//                        onProceed: { password in viewModel.createBackup(password: password) },
//                        onCancel: { viewModel.cancel() }
//                    )
//                    .interactiveDismissDisabled()
//                    .presentationDetents([.large])
//                }
            }

            // TODO: conflict with presentation
            .alert(
                viewModel.alertContent.title,
                isPresented: $viewModel.isAlertPresented
            ) {
                Button("OK") { // TODO: fix and localize
                    // Handle the acknowledgement.
                }
            } message: {
                Text("Please check your credentials and try again.")
            }
        }
    }
}

#Preview {
    ImportBackupPreview()
}
