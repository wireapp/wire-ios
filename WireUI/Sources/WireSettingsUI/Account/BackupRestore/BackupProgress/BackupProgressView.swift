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

struct BackupProgressView: View {

    var state: CreateBackupState
    var cancelAction: () -> Void

    var body: some View {

        NavigationStack {
            BackupProgressViewControllerRepresentable(state, cancelAction)
                .navigationTitle("title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton(
                            action: { /*dismiss()*/ },
                            accessibilityLabel: L10n.Accessibility.SetBackupPassword.Close.label
                        )
                    }
                }
        }

//        switch state {
//        case .inProgress(let progress):
//            VStack {
//                Text("\(progress)")
//                Button("cancel") {
//                    cancelAction()
//                }
//            }
//        case .ready(let url):
//            VStack {
//                Text("backup ready")
//                ShareLink(
//                    item: url,
//                    preview: SharePreview("Backup File", image: Image(systemName: "archivebox"))
//                ) {
//                    Label("Share Backup", systemImage: "square.and.arrow.up")
//                }
//            }
//        }
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

    var state: BackupProgressView.CreateBackupState
    var cancelAction: () -> Void

    init(
        _ state: BackupProgressView.CreateBackupState,
        _ cancelAction: @escaping () -> Void
    ) {
        self.state = state
        self.cancelAction = cancelAction
    }

    func makeUIViewController(context: Context) -> BackupProgressViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: BackupProgressViewController, context: Context) {
        //
    }
}

private final class BackupProgressViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(type: .system)
        button.setTitle("save", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(showFileExporter(_:)), for: .primaryActionTriggered)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc
    private func showFileExporter(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [URL(fileURLWithPath: "/")], applicationActivities: nil)
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame
        }
        present(activityViewController, animated: true)
    }
}
