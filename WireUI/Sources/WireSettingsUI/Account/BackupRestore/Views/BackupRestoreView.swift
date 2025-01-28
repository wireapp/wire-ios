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

    typealias ExportBackupAction = (_ password: String) -> Void

    @ObservedObject private(set) var viewModel: BackupRestoreViewModel

    @ViewBuilder private(set) var exportBackupSheetContent: (@escaping ExportBackupAction) -> ExportBackupSheet
    @ViewBuilder private(set) var importBackupSheetContent: () -> ImportBackupSheet

    /// Workaround for not being able to use `ShareLink` because 1. there is no callback which allows us to delete
    /// the temporary file and 2. another step would be needed: A view showing the `ShareLink` right after the backup file became ready.
    private(set) var presentActivityViewController: (_ url: URL, _ anchor: UIViewController) async -> Void

    @State private var isSetExportPasswordUIPresented = false
    @State private var isExportBackupSheetPresented = false
    @State private var isBackupPickerPresented = false
    @State private var popoverPresenter = UIViewController()

    @State private var isImportBackupSheetPresented = false
    @State private var selectedFileURL: URL?

    /// `nil` means the ExportBackupSheet has not been opened or has been dismissed without the texport action.
    @State private var exportBackupPassword: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        List {
            backupSection
            restoreSection
        }
        .listStyle(.grouped)
        .background(Color(ColorTheme.Backgrounds.background))
        .scrollContentBackground(.hidden)
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    }

    @ViewBuilder
    private var backupSection: some View {

        let backUpNowButton = Button(action: { isSetExportPasswordUIPresented = true /*isExportBackupSheetPresented.toggle()*/ }) {
            Text(L10n.Localizable.Settings.ExportBackup.action)
                .wireTextStyle(.body2)
                .foregroundStyle(Color.primaryText)
        }

        Section(footer: Text(L10n.Localizable.Settings.ExportBackup.description)) {
            if horizontalSizeClass == .regular, #available(iOS 18.0, *) {
                backUpNowButton
                    .sheet(isPresented: $isSetExportPasswordUIPresented) {
                        Text("TODO")
                            .frame(width: 300, height: 150)
                            .presentationSizing(
                                .page
                                    .fitted(horizontal: true, vertical: true)
                                    .sticky(horizontal: false, vertical: true)
                            )
                    }
            } else {
                backUpNowButton
                .background {
                    // a view controller just for presenting a popover presentation
                    PopoverPresenter { popoverPresenter = $0 }
                }
                .sheet(
                    isPresented: $isExportBackupSheetPresented,
                    onDismiss: {
                        // if the ExportBackupSheet left a password after dismiss, trigger the action
                        exportBackupPassword.map { password in
                            viewModel.backupActiveAccount(
                                password: password,
                                export: { url in
                                    await presentActivityViewController(url, popoverPresenter)
                                }
                            )
                        }
                        exportBackupPassword = nil
                    }) {
                        // get the password from the ExportBackupSheet
                        exportBackupSheetContent({ password in
                            exportBackupPassword = password
                        })
                    }
            }
        }
    }

    @ViewBuilder
    private var restoreSection: some View {
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
}

private struct PopoverPresenter: UIViewControllerRepresentable {

    /// Used for extracting the reference to the created view controller.
    let viewControllerCreated: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewControllerCreated(viewController)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    BackupRestoreViewPreview()
}
