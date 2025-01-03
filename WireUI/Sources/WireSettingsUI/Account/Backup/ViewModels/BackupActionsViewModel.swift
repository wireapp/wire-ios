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

public final class BackupActionsViewModel: ObservableObject {
    @Published var sections: [BackupActionsSection] = []

    private let backupSource: any BackupSource
    private let onSuccessHandler: ((URL, @escaping () -> Void) -> Void)
    private let onFailureHandler: ((any Error) -> Void)

    public init(
        backupSource: any BackupSource,
        onSuccessHandler: @escaping ((URL, @escaping () -> Void) -> Void),
        onFailureHandler: @escaping ((any Error) -> Void)
    ) {
        self.backupSource = backupSource
        self.onSuccessHandler = onSuccessHandler
        self.onFailureHandler = onFailureHandler

        sections = [
            BackupActionsSection(type: .backup)
            //BackupActionsSection(type: .restore)
        ]
    }

    func backupActiveAccount(password: String) {
        do {
            let backupPath = try backupSource.backupActiveAccount(password: password)
            onSuccessHandler(backupPath) { [weak self] in
                self?.backupSource.clearPreviousBackups()
            }
        } catch {
            onFailureHandler(error)
        }
    }
}
