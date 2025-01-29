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

public struct BackupRestoreBuilder {

    public var backupPasswordValidator: any BackupPasswordValidatorProtocol
    public var exportBackupUseCase: any ExportBackupUseCaseProtocol

    public init(
        backupPasswordValidator: any BackupPasswordValidatorProtocol,
        exportBackupUseCase: any ExportBackupUseCaseProtocol
    ) {
        self.backupPasswordValidator = backupPasswordValidator
        self.exportBackupUseCase = exportBackupUseCase
    }

    @MainActor
    public func build() -> UIViewController {
        let viewModel = BackupRestoreViewModel(exportBackupUseCase: exportBackupUseCase)
        return BackupRestoreViewController(
            viewModel: viewModel,
            backupPasswordValidator: backupPasswordValidator
        )
    }

    @MainActor
    public static func tmp() -> some View {
        BackupRestoreRootView(viewModel: .init())
    }
}
