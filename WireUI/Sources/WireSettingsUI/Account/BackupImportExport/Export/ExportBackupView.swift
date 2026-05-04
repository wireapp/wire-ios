//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLocators

struct ExportBackupView<PasswordView: View, ProgressView: View>: View {

    @StateObject var viewModel: ExportBackupViewModel

    private(set) var setBackupPasswordView: () -> PasswordView
    private(set) var creatingBackupProgressView: () -> ProgressView

    private typealias Strings = L10n.Localizable

    var body: some View {

        Section(footer: Text(Strings.Backup.Export.description)) {

            Button(Strings.Backup.Export.action, action: viewModel.showPasswordDialog)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.primaryText)
                .sheet(isPresented: $viewModel.isCreatingBackupProgressPresented) {
                    creatingBackupProgressView()
                        .interactiveDismissDisabled()
                        .presentationDetents([.medium])
                        .sheet(isPresented: $viewModel.isSetBackupPasswordPresented) {
                            setBackupPasswordView()
                                .interactiveDismissDisabled()
                                .presentationDetents([.medium])
                        }
                }

                .alert(Strings.ExportBackup.ErrorAlert.title, isPresented: $viewModel.isErrorAlertPresented) {
                    Button(Strings.ExportBackup.ErrorAlert.ok, action: viewModel.reset)
                } message: {
                    Text(Strings.ExportBackup.ErrorAlert.message)
                }
                .accessibilityIdentifier(Locators.BackupOrRestorePage.backUpNow.rawValue)

        }
    }
}

#Preview {
    ExportBackupPreview()
}
