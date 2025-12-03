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
    private let isContextMenuAllowed: Bool

    private typealias BackupStrings = L10n.Localizable.Backup
    private typealias ImportBackupAlertStrings = L10n.Localizable.ImportBackup.Alert
    private typealias OverwriteConfirmationStrings = L10n.Localizable.ImportBackup.OverwriteConfirmation

    init(viewModel: ImportBackupViewModel, isContextMenuAllowed: Bool) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    var body: some View {
        Section(footer: Text(BackupStrings.Import.description)) {

            Button(BackupStrings.Import.action) {
                isFileImporterPresented = true
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.primaryText)
            .fileImporter(
                isPresented: $isFileImporterPresented,
                // Workaround: Google Drive doesn't recognize Wire backup
                // UTIs so if we only allow them, the user won't be able
                // to select Wire backups stored in Google Drive.
                // Instead, we allow any file and then we'll validate the
                // file type afterwards.
                allowedContentTypes: [.data],
                onCompletion: viewModel.pickedBackupFile
            )

            .sheet(isPresented: $viewModel.isImportProgressPresented) {

                ImportProgressView(
                    isLoadingFile: viewModel.isLoadingFile,
                    progressValues: viewModel.importProgress,
                    cancelAction: viewModel.reset
                )
                .interactiveDismissDisabled()
                .presentationDetents([.medium])
                .sheet(isPresented: $viewModel.isEnterBackupPasswordPresented) {
                    EnterPasswordView(
                        password: $viewModel.backupPassword,
                        passwordIsWrong: $viewModel.isBackupPasswordWrong,
                        continueAction: { viewModel.enterPassword($0) },
                        cancelAction: viewModel.reset,
                        isContextMenuAllowed: isContextMenuAllowed
                    )
                    .interactiveDismissDisabled()
                    .presentationDetents([.large])
                    .onChange(of: viewModel.backupPassword) { _ in
                        if viewModel.isBackupPasswordWrong {
                            viewModel.isBackupPasswordWrong = false
                        }
                    }
                }

                .alert(viewModel.alertContent.title, isPresented: $viewModel.isImportConfirmationPresented) {
                    Button(OverwriteConfirmationStrings.cancel, role: .cancel, action: viewModel.reset)
                    Button(OverwriteConfirmationStrings.proceed, role: .destructive, action: viewModel.confirmOverwrite)
                } message: {
                    Text(viewModel.alertContent.message)
                }
            }

            .alert(viewModel.alertContent.title, isPresented: $viewModel.isAlertPresented) {
                Button(ImportBackupAlertStrings.ok, action: viewModel.reset)
            } message: {
                Text(viewModel.alertContent.message)
            }
        }
    }
}

#Preview {
    ImportBackupPreview()
}
