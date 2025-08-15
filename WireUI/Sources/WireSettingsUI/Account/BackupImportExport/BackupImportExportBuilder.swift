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
import WireDomainPackage
import WireFoundation
import WireLogging

public struct BackupImportExportBuilder {

    let backupPasswordValidator: any BackupPasswordValidatorProtocol
    let createBackupUseCase: any CreateBackupUseCaseProtocol
    let importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol
    let cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol
    let exportBackupLogger: any LoggerProtocol
    let importBackupLogger: any LoggerProtocol
    let wireAccentColor: WireAccentColor
    let wireAccentColorMapping: WireAccentColorMapping
    let isContextMenuAllowed: Bool

    public init(
        backupPasswordValidator: any BackupPasswordValidatorProtocol,
        createBackupUseCase: any CreateBackupUseCaseProtocol,
        importBackupUseCaseFactory: any ImportBackupUseCaseFactoryProtocol,
        cleanUpBackupsUseCase: any CleanUpBackupsUseCaseProtocol,
        exportBackupLogger: any LoggerProtocol,
        importBackupLogger: any LoggerProtocol,
        wireAccentColorMapping: WireAccentColorMapping,
        wireAccentColor: WireAccentColor,
        isContextMenuAllowed: Bool
    ) {
        self.backupPasswordValidator = backupPasswordValidator
        self.createBackupUseCase = createBackupUseCase
        self.importBackupUseCaseFactory = importBackupUseCaseFactory
        self.cleanUpBackupsUseCase = cleanUpBackupsUseCase
        self.exportBackupLogger = exportBackupLogger
        self.importBackupLogger = importBackupLogger
        self.wireAccentColorMapping = wireAccentColorMapping
        self.wireAccentColor = wireAccentColor
        self.isContextMenuAllowed = isContextMenuAllowed
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
        .environment(\.wireAccentColorMapping, wireAccentColorMapping)
        .environment(\.wireAccentColor, wireAccentColor)
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

        SetBackupPasswordView(viewModel: setBackupPasswordViewModel, isContextMenuAllowed: isContextMenuAllowed)

    }

    @MainActor @ViewBuilder
    func buildImportBackupView() -> some View {

        let viewModel = ImportBackupViewModel(
            importBackupUseCaseFactory: importBackupUseCaseFactory,
            logger: importBackupLogger
        )
        ImportBackupView(viewModel: viewModel, isContextMenuAllowed: isContextMenuAllowed)

    }
}

// MARK: - BackupImportExportBuilder + preview

extension BackupImportExportBuilder {

    static var previewBuilder: BackupImportExportBuilder {
        BackupImportExportBuilder(
            backupPasswordValidator: PreviewBackupPasswordValidator(),
            createBackupUseCase: PreviewCreateBackupUseCase(),
            importBackupUseCaseFactory: PreviewImportBackupUseCaseFactory(),
            cleanUpBackupsUseCase: PreviewCleanUpBackupsUseCase(),
            exportBackupLogger: PreviewLogger(),
            importBackupLogger: PreviewLogger(),
            wireAccentColorMapping: WireAccentColorMapping(),
            wireAccentColor: .purple,
            isContextMenuAllowed: true
        )
    }
}
