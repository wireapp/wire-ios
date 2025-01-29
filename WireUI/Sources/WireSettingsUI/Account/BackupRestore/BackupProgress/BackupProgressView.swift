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
        switch state {
        case .inProgress(let progress):
            BackupProgressViewControllerRepresentable(
                progressDescription: "saving",
                progressValue: progress,
                isExportButtonEnabled: false
            )
        case .ready(let url):
            BackupProgressViewControllerRepresentable(
                progressDescription: "success",
                progressValue: 1,
                isExportButtonEnabled: true
            )
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

    @State var progressDescription = ""
    @State var progressValue = Float()
    @State var isExportButtonEnabled = false

    func makeUIViewController(context: Context) -> BackupProgressViewController {
        let viewController = BackupProgressViewController()
        viewController.progressDescription = progressDescription
        viewController.progressValue = progressValue
        viewController.isExportButtonEnabled = isExportButtonEnabled
        return viewController
    }

    func updateUIViewController(_ viewController: BackupProgressViewController, context: Context) {
        viewController.progressDescription = progressDescription
        viewController.progressValue = progressValue
        viewController.isExportButtonEnabled = isExportButtonEnabled
    }
}

private final class BackupProgressViewController: UIViewController {

    var progressDescription: String {
        get { descriptionLabel.text ?? "" }
        set { descriptionLabel.text = newValue }
    }

    var progressValue: Float {
        get { progressView.progress }
        set { progressView.progress = newValue }
    }

    var isExportButtonEnabled: Bool { // TODO: url instead
        get { exportButton.isEnabled }
        set { exportButton.isEnabled = newValue }
    }

    private var descriptionLabel: UILabel!
    private var progressView: UIProgressView!
    private var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel = .init()

        progressView = .init(progressViewStyle: .bar)

        exportButton = .init(type: .system)
        exportButton.setTitle("save", for: .normal)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        view.addSubview(exportButton)

        NSLayoutConstraint.activate([
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc
    private func showActivityViewController(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [URL(fileURLWithPath: "/")], applicationActivities: nil)
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame
        }
        present(activityViewController, animated: true)
    }
}
