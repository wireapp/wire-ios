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

struct BackupRestoreRootView: View {

    @ObservedObject var viewModel: BackupRestoreRootViewModel

    var body: some View {

        BackupRestoreMainView(
            backupAction: { viewModel.requestBackupPassword() },
            restoreAction: { _ in print("restore") }
        )

        .sheet(isPresented: $viewModel.isSetBackupPasswordVisible) {
            SetBackupPasswordView { password in
                guard let password else { return viewModel.cancel() }
                viewModel.createBackup(password: password)
            }
            .interactiveDismissDisabled()
            .presentationDetents([.large])
        }

        .sheet(isPresented: $viewModel.isBackupProgressVisible) {
            BackupProgressView(
                state: .inProgress(viewModel.backupProgress!),
                cancelAction: { viewModel.cancel() }
            )
            .interactiveDismissDisabled()
            .presentationDetents([.medium])
        }

    }
}

#Preview {
    BackupRestoreRootView(viewModel: BackupRestoreRootViewModel())
}

extension BackupRestoreRootViewModel.State {
    fileprivate var isEnterBackupPasswordStep: Bool {
        if case .backup(.enterPassword) = self { true } else { false }
    }
}
