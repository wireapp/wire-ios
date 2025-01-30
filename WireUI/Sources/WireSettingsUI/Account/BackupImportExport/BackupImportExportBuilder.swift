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

public struct BackupImportExportBuilder {

    let backupPasswordValidator: any BackupPasswordValidatorProtocol
    let exportBackupUseCase: any CreateBackupUseCaseProtocol
    let importBackupUseCase: any ImportBackupUseCaseProtocol
    let cleanUpBackupsUseCaseProtocol: any CleanUpBackupsUseCaseProtocol

    public init(
        backupPasswordValidator: any BackupPasswordValidatorProtocol,
        exportBackupUseCase: any CreateBackupUseCaseProtocol,
        importBackupUseCase: any ImportBackupUseCaseProtocol,
        cleanUpBackupsUseCaseProtocol: any CleanUpBackupsUseCaseProtocol
    ) {
        self.backupPasswordValidator = backupPasswordValidator
        self.exportBackupUseCase = exportBackupUseCase
        self.importBackupUseCase = importBackupUseCase
        self.cleanUpBackupsUseCaseProtocol = cleanUpBackupsUseCaseProtocol
    }

    @MainActor
    public func build() -> UIViewController {
        UIHostingController(
            rootView: BackupImportExportRootView {
                ExportBackupView(viewModel: .init(exportBackupUseCase: exportBackupUseCase))
                ImportBackupView(viewModel: .init(importBackupUseCase: importBackupUseCase))
            }
        )
    }
}
