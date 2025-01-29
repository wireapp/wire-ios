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

struct SetExportPasswordPreview: View {

    @State private var isPresented = true

    var body: some View {
        Button(L10n.Localizable.ExportBackup.button) {
            isPresented.toggle()
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                SetExportPasswordView(
                    viewModel: .init(
                        passwordValidator: MockBackupPasswordValidator(),
                        exportBackupAction: { _ in }
                    )
                )
            }
            .background(Color.blue)
            .interactiveDismissDisabled()
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(300)])
//            .presentationDetents([.height(100), .fraction(20), .medium, .large])
        }
    }
}

//private struct PreviewAlertPresenter: BackupRestoreAlertPresenterProtocol {
//    func todo() async -> Bool {
//        fatalError("not implemented")
//    }
//}
//
//private struct PreviewUseCase: ExportBackupUseCaseProtocol {
//    func invoke(password: String) async throws {
//        fatalError("not implemented")
//    }
//}

//private struct PreviewActivityPresenter: ExportBackupActivityPresenterProtocol {
//    func present(backup: URL) async {}
//}
