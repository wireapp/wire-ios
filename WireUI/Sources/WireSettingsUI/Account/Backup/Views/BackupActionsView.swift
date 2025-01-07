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
    @ObservedObject private var viewModel: BackupActionsViewModel
    @State private var isExportBackupSheetPresented: Bool = false
    @State private var isBackupPickerPresented: Bool = false

    public init(viewModel: BackupActionsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section(
                footer: Text(L10n.Settings.ExportBackup.description)
            ) {
                Button(action: {
                    isExportBackupSheetPresented.toggle()
                }, label: {
                    HStack {
                        Text(L10n.ExportBackup.title)
                            .font(.textStyle(.body2))
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
                    .presentationDetents([.medium, .large])
                }
            }

            Section(
                footer: Text(L10n.Settings.RestoreFromBackup.description)
            ) {
                Button(action: {
                    isBackupPickerPresented.toggle()
                }, label: {
                    HStack {
                        Text(L10n.RestoreFromBackup.title)
                            .font(.textStyle(.body2))
                            .foregroundStyle(Color.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.primary)
                    }
                })
                .fullScreenCover(isPresented: $isBackupPickerPresented) {
                    DocumentPicker { url in
                        if let fileURL = url {
                            print("Selected file URL: \(fileURL)")
                        }
                    }
                }
            }
        }
        .listStyle(.grouped)
        .listRowBackground(Color(ColorTheme.Backgrounds.background))
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var completion: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var completion: (URL?) -> Void

        init(completion: @escaping (URL?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completion(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}

#Preview {
    BackupActionsPreview()
}
