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

struct CreatingBackupProgressView: View {

    var progress: CreatingBackupProgressModel
    var cancelAction: () -> Void

    var body: some View {
        NavigationStack {
            backupProgressViewControllerRepresentable
                .navigationTitle("title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton(
                            action: cancelAction,
                            accessibilityLabel: L10n.Accessibility.SetBackupPassword.Close.label
                        )
                    }
                }
        }
    }

    private var backupProgressViewControllerRepresentable: some View {
        switch progress {
        case .ongoing(let progress):
            BackupProgressViewControllerRepresentable(
                progressDescription: "saving \n A b c de fkalfj d lsdkfjsdklfsdjk fsdlkjf sdlkfsdkl fjsdlk flskj dlsdjfl k",
                progressValue: progress,
                backupURL: nil
            )
        case .finished(let url):
            BackupProgressViewControllerRepresentable(
                progressDescription: "success",
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
