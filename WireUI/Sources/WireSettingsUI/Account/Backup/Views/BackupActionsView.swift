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
    @State private var isBackupSheetPresented: Bool = false
    @State private var isRestoreSheetPresented: Bool = false

    public init(viewModel: BackupActionsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(
                    footer: section.type.footer
                ) {
                    Button(action: {
                        switch section.type {
                        case .backup:
                            isRestoreSheetPresented = false
                            isBackupSheetPresented.toggle()
                        case .restore:
                            isBackupSheetPresented = false
                            isRestoreSheetPresented.toggle()
                        }
                    }
                    ) {
                        HStack {
                            section.type.title
                                .font(.textStyle(.body2))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.primary)
                        }
                    }
                    .sheet(isPresented: $isBackupSheetPresented) {
                        NavigationStack {
                            ExportBackupView(
                                passwordValidator:
                                    viewModel.passwordValidator) { password in
                                        viewModel.backupActiveAccount(password: password)
                                    }
                        }
                        .presentationDetents([.medium, .large])
                    }
                }
            }
        }
        .listStyle(.grouped)
        .listRowBackground(Color(ColorTheme.Backgrounds.background))
    }
}

#Preview {
    BackupActionsView(viewModel: BackupActionsViewModel(
        backupSource: MockBackupSource(),
        backupHandler: BackupHandler(
            onSuccess: { _, _  in },
            onFailure: { _ in }),
        passwordValidator: MockBackupPasswordValidator()
    ))
}

private class MockBackupSource: BackupSourceProtocol {
    func backupActiveAccount(password: String) throws -> URL {
        return URL(fileURLWithPath: "path")
    }

    func clearPreviousBackups() {}
}

class MockBackupPasswordValidator: BackupPasswordValidatorProtocol {
    func isValid(password: String) -> Bool {
        true
    }

    var localizedRulesDescription: String {
        "Use at least 8 characters, with one lowercase letter, one capital letter, a number, and a special character."
    }
}
