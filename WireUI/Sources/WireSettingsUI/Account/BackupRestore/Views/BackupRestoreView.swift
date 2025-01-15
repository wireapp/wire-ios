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

struct BackupRestoreView<ExportBackupSheet: View, ImportBackupSheet: View>: View {

    @ObservedObject private(set) var viewModel: BackupRestoreViewModel

    @ViewBuilder private(set) var exportBackupSheetContent: () -> ExportBackupSheet
    @ViewBuilder private(set) var importBackupSheetContent: () -> ImportBackupSheet

    @State private var isExportBackupSheetPresented: Bool = false
    @State private var isImportBackupSheetPresented: Bool = false
    @State private var isBackupPickerPresented: Bool = false
    @State private var selectedFileURL: URL?

    var body: some View {
        List {
            Section(footer: Text(L10n.Localizable.Settings.ExportBackup.description)) {
                Button {
                    isExportBackupSheetPresented.toggle()
                } label: {
                    Text(L10n.Localizable.Settings.ExportBackup.action)
                        .wireTextStyle(.body2)
                        .foregroundStyle(Color.primaryText)
                }
                .sheet(isPresented: $isExportBackupSheetPresented, content: exportBackupSheetContent)
            }

            Section(footer: Text(L10n.Localizable.Settings.RestoreFromBackup.description)) {
                Button {
                    viewModel.confirmBackupRestore {
                        isBackupPickerPresented.toggle()
                    }
                } label: {
                    Text(L10n.Localizable.Settings.RestoreFromBackup.action)
                        .font(.textStyle(.body2))
                        .foregroundStyle(Color.primaryText)
                }
                .fullScreenCover(isPresented: $isBackupPickerPresented) {
                    BackupPicker { url in
                        if let fileURL = url {
                            selectedFileURL = fileURL
                            isImportBackupSheetPresented = true
                        }
                    }
                }
                .sheet(isPresented: $isImportBackupSheetPresented, content: importBackupSheetContent)
            }
        }
        .listStyle(.grouped)
        .background(Color(ColorTheme.Backgrounds.background))
        .scrollContentBackground(.hidden)
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }
}

#Preview {
    BackupRestoreViewPreview()
}
