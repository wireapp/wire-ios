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
import WireLocators

struct CreatingBackupProgressView: View {

    var progress: CreatingBackupProgressModel
    var cancelAction: () -> Void

    private typealias Strings = L10n.Localizable.ExportBackup
    private typealias Labels = L10n.Accessibility.ExportBackup

    var body: some View {
        NavigationStack {
            backupProgressView
                .background(ColorTheme.Backgrounds.background.color)
                .navigationTitle(Strings.CreatingBackup.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Strings.Cancel.title, action: cancelAction)
                            .accessibilityLabel(Labels.Cancel.label)
                            .accessibilityIdentifier("cancel")
                    }
                }
                .accessibilityIdentifier(Locators.CreatingBackupPage.creatingBackupPageLabel.rawValue)
        }
    }

    @ViewBuilder private var backupProgressView: some View {

        let completedAction: (Bool) -> Void = { completed in
            completed ? cancelAction() : ()
        }

        switch progress {

        case let .ongoing(current, total):
            BackupProgressViewControllerRepresentable(
                progressDescription: .init(localized: "exportBackup.creatingBackup.saving", bundle: .module),
                progressValues: (current, total),
                backupURL: nil,
                completedAction: completedAction
            )

        case let .finished(url):
            BackupProgressViewControllerRepresentable(
                progressDescription: .init(localized: "exportBackup.creatingBackup.success", bundle: .module),
                progressValues: (1, 1),
                backupURL: url,
                completedAction: completedAction
            )
            .accessibilityIdentifier(Locators.CreatingBackupPage.backupProgressFinished.rawValue)
        }
    }

}

#Preview("in progress") {
    CreatingBackupProgressPreview(.ongoing(current: 1, total: 4))
        .tint(Color.purple)
}

#Preview("ready") {
    CreatingBackupProgressPreview(.finished(.init(fileURLWithPath: "/")))
        .tint(Color.purple)
}
