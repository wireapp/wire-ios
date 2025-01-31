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
import WireReusableUIComponents
import WireDesign

struct CreatingBackupProgressView: View {

    var progress: CreatingBackupProgressModel
    var cancelAction: () -> Void

    var body: some View {
        NavigationStack {
            backupProgressViewControllerRepresentable
                .background(Color(uiColor: ColorTheme.Backgrounds.background))
                .navigationTitle(Text("creatingBackup.title", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: cancelAction) {
                            Text("creatingBackup.cancel", bundle: .module)
                        }
                        .foregroundStyle(Color(uiColor: ColorTheme.Base.primary))
                        .accessibilityLabel(Text("creatingBackup.cancel.label"))
                        .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    private var backupProgressViewControllerRepresentable: some View {
        switch progress {
        case .ongoing(let progress):
            BackupProgressViewControllerRepresentable(
                progressDescription: .init(localized: "creatingBackup.savingConversationHistory", bundle: .module),
                progressValue: progress,
                backupURL: nil
            )
        case .finished(let url):
            BackupProgressViewControllerRepresentable(
                progressDescription: .init(localized: "creatingBackup.backupSuccessfullyCreated", bundle: .module),
                progressValue: 1,
                backupURL: url
            )
        }
    }

}

#Preview("in progress") {
    CreatingBackupProgressPreview(.ongoing(0.25))
}

#Preview("ready") {
    CreatingBackupProgressPreview(.finished(.init(fileURLWithPath: "/")))
}
