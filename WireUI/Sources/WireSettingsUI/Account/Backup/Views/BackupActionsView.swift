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
import WireReusableUIComponents

public struct BackupActionsView: View {
    @ObservedObject private var viewModel: BackupRestoreViewModel
    @State private var isExportBackupSheetPresented: Bool = false
    @State private var isBackupPickerPresented: Bool = false
    @State private var isRestoreBackupSheetPresented: Bool = false
    @State private var selectedFileURL: URL?

    public init(viewModel: BackupRestoreViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section(
                footer: Text(L10n.Localizable.Settings.ExportBackup.description)
            ) {
                Button(action: {
                    isExportBackupSheetPresented.toggle()
                }, label: {
                    HStack {
                        Text(L10n.Localizable.Settings.ExportBackup.action)
                            .wireTextStyle(.body2)
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.primary)
                    }
                })
                .sheet(isPresented: $isExportBackupSheetPresented) {
                    NavigationStack {
                        ExportBackupView(
                            passwordValidator: viewModel.passwordValidator,
                            exportBackup: { password in
                                viewModel.backupActiveAccount(password: password)
                            }
                        )
                    }
                    .presentationDetents([.medium])
                }
            }
            .listRowBackground(Color(ColorTheme.Backgrounds.surface))

            Section(
                footer: Text(L10n.Localizable.Settings.RestoreFromBackup.description)
            ) {
                Button(action: {
                    viewModel.confirmBackupRestore {
                        isBackupPickerPresented.toggle()
                    }
                }, label: {
                    HStack {
                        Text(L10n.Localizable.Settings.RestoreFromBackup.action)
                            .font(.textStyle(.body2))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.primary)
                    }
                })
                .fullScreenCover(isPresented: $isBackupPickerPresented) {
                    BackupPicker { url in
                        if let fileURL = url {
                            selectedFileURL = fileURL
                            isRestoreBackupSheetPresented = true
                        }
                    }
                }
                .sheet(isPresented: $isRestoreBackupSheetPresented) {
                    NavigationStack {
                        RestoreBackupView { password in
                            if let fileURL = selectedFileURL {
                                viewModel.restoreFromBackup(
                                    at: fileURL,
                                    password: password,
                                    completion: { _ in }
                                )
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .listRowBackground(Color(ColorTheme.Backgrounds.surface))
        }
        .listStyle(.grouped)
        .background(Color(ColorTheme.Backgrounds.background))
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    BackupActionsPreview()
}
