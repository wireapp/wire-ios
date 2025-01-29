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

struct BackupProgressView: View {

    /// The percentage value of the progess or `nil` when the backup is ready.
    var state: CreateBackupState
    var cancelAction: () -> Void

    var body: some View {
        switch state {
        case .inProgress(let progress):
            VStack {
                Text("\(progress)")
                Button("cancel") {
                    cancelAction()
                }
            }
        case .ready(let url):
            VStack {
                Text("backup ready")
                ShareLink(
                    item: url,
                    preview: SharePreview("Backup File", image: Image(systemName: "archivebox"))
                ) {
                    Label("Share Backup", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    enum CreateBackupState {
        case inProgress(_ percentage: Float)
        case ready(_ url: URL)
    }
}

#Preview("in progress") {
    Color.white
        .sheet(isPresented: .constant(true)) {
            BackupProgressView(
                state: .inProgress(0.25),
                cancelAction: {}
            )
            .presentationDetents([.medium])
        }
}

#Preview("ready") {
    Color.white
        .sheet(isPresented: .constant(true)) {
            BackupProgressView(
                state: .ready(.init(fileURLWithPath: "/")),
                cancelAction: {}
            )
            .presentationDetents([.medium])
        }
}

private struct BackupProgressViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> BackupProgressViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: BackupProgressViewController, context: Context) {
        //
    }
}

private final class BackupProgressViewController: UIViewController {}
