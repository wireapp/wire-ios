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
import WireDomainPkg
import WireLogging

public struct BackupImportExportBuilder {

    let backupPasswordValidator: any BackupPasswordValidatorProtocol
    let createBackupUseCase: any CreateBackupUseCaseProtocol
    let importBackupUseCase: any ImportBackupUseCaseProtocol
    let cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol
    let exportBackupLogger: any LoggerProtocol
    let importBackupLogger: any LoggerProtocol

    public init(
        backupPasswordValidator: any BackupPasswordValidatorProtocol,
        createBackupUseCase: any CreateBackupUseCaseProtocol,
        importBackupUseCase: any ImportBackupUseCaseProtocol,
        cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol,
        exportBackupLogger: any LoggerProtocol,
        importBackupLogger: any LoggerProtocol
    ) {
        self.backupPasswordValidator = backupPasswordValidator
        self.createBackupUseCase = createBackupUseCase
        self.importBackupUseCase = importBackupUseCase
        self.cleanUpBackupsUseCase = cleanUpBackupsUseCase
        self.exportBackupLogger = exportBackupLogger
        self.importBackupLogger = importBackupLogger
    }

    @MainActor
    public func build() -> UIViewController {
        UIHostingController(rootView: buildRootView())
    }

    @MainActor @ViewBuilder
    func buildRootView() -> some View {
        BackupImportExportRootView {
            buildExportBackupView()
            buildImportBackupView()
        }
    }

    @MainActor @ViewBuilder
    func buildExportBackupView() -> some View {

        let viewModel = ExportBackupViewModel(
            createBackupUseCase: createBackupUseCase,
            cleanUpBackupsUseCase: cleanUpBackupsUseCase,
            logger: exportBackupLogger
        )

        ExportBackupView(
            viewModel: viewModel,
            setBackupPasswordView: {
                buildSetBackupPasswordView(
                    cancelAction: { [weak viewModel] in viewModel?.cancel() },
                    setPasswordAction: { [weak viewModel] password in viewModel?.createBackup(password: password) }
                )
            },
            creatingBackupProgressView: {
                CreatingBackupProgressView(
                    progress: viewModel.backupProgress,
                    cancelAction: { viewModel.cancel() }
                )
            }
        )

    }

    @MainActor @ViewBuilder
    func buildSetBackupPasswordView(
        cancelAction: @escaping () -> Void,
        setPasswordAction: @escaping (_ password: String) -> Void
    ) -> some View {

        let setBackupPasswordViewModel = SetBackupPasswordViewModel(
            passwordValidator: backupPasswordValidator,
            cancelAction: cancelAction,
            setPasswordAction: setPasswordAction
        )

        SetBackupPasswordView(viewModel: setBackupPasswordViewModel)

    }

    @MainActor @ViewBuilder
    func buildImportBackupView() -> some View {

        let viewModel = ImportBackupViewModel(
            importBackupUseCase: importBackupUseCase,
            logger: importBackupLogger
        )
        ImportBackupView(viewModel: viewModel)

    }
}

// MARK: - BackupImportExportBuilder + preview

extension BackupImportExportBuilder {

    static var previewBuilder: BackupImportExportBuilder {
        BackupImportExportBuilder(
            backupPasswordValidator: PreviewBackupPasswordValidator(),
            createBackupUseCase: PreviewCreateBackupUseCase(),
            importBackupUseCase: PreviewImportBackupUseCase(),
            cleanUpBackupsUseCase: PreviewCleanUpBackupsUseCase(),
            exportBackupLogger: PreviewLogger(),
            importBackupLogger: PreviewLogger()
        )
    }
}
