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
                progressDescription: "saving \n A b c de fkalfj d lsdkfjsdklfsdjk fsdlkjf sdlkfsdkl fjsdlk flskj dlsdjfl k",
                progressValue: progress,
                backupURL: nil
            )
        case .ready(let url):
            BackupProgressViewControllerRepresentable(
                progressDescription: "success",
                progressValue: 1,
                backupURL: url
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

    var progressDescription = ""
    var progressValue = Float()
    var backupURL: URL?

    func makeUIViewController(context: Context) -> BackupProgressViewController {
        let viewController = BackupProgressViewController()
        viewController.progressDescription = progressDescription
        viewController.progressValue = progressValue
        viewController.backupURL = backupURL
        return viewController
    }

    func updateUIViewController(_ viewController: BackupProgressViewController, context: Context) {
        print("updating progress \(progressValue)")
        viewController.progressDescription = progressDescription
        viewController.progressValue = progressValue
        viewController.backupURL = backupURL
    }
}

private final class BackupProgressViewController: UIViewController {

    var progressDescription = "" {
        didSet { descriptionLabel?.text = progressDescription }
    }

    var progressValue = Float() {
        didSet { progressView?.progress = progressValue }
    }

    var backupURL: URL? {
        didSet { exportButton?.isEnabled = backupURL != nil }
    }

    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var descriptionLabel: UILabel!
    private var progressView: UIProgressView!
    private var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel = .init()
        descriptionLabel.numberOfLines = 0
//        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(descriptionLabel)
        descriptionLabel.text = progressDescription

        progressView = .init(progressViewStyle: .bar)
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(progressView)
        progressView.progress = progressValue

        exportButton = .init(type: .system)
        exportButton.setTitle("save", for: .normal)
//        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        exportButton.isEnabled = backupURL != nil
//        view.addSubview(exportButton)

        /*
        NSLayoutConstraint.activate([

            descriptionLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 3),
            descriptionLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.topAnchor, multiplier: 3),
            view.trailingAnchor.constraint(equalToSystemSpacingAfter: descriptionLabel.trailingAnchor, multiplier: 3),

            progressView.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            progressView.topAnchor.constraint(equalToSystemSpacingBelow: descriptionLabel.bottomAnchor, multiplier: 3),
            descriptionLabel.trailingAnchor.constraint(equalTo: progressView.trailingAnchor),

            exportButton.leadingAnchor.constraint(equalTo: descriptionLabel.leadingAnchor),
            exportButton.topAnchor.constraint(equalToSystemSpacingBelow: progressView.bottomAnchor, multiplier: 3),
            descriptionLabel.trailingAnchor.constraint(equalTo: exportButton.trailingAnchor),
            view.bottomAnchor.constraint(equalToSystemSpacingBelow: exportButton.bottomAnchor, multiplier: 3)
        ])
         */

        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])

        stackView = UIStackView(arrangedSubviews: [descriptionLabel, progressView, exportButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([

            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: scrollView.contentLayoutGuide.leadingAnchor, multiplier: 3),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: scrollView.contentLayoutGuide.topAnchor, multiplier: 3),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 3),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 3)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let stackViewHeight = stackView.frame.maxY + (navigationController?.navigationBar.frame.height ?? 0)
        if let sheetPresentationController = navigationController?.sheetPresentationController {
            sheetPresentationController.detents = [.custom { _ in stackViewHeight }]
            print("setting detend to \(stackViewHeight)")
        }
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
