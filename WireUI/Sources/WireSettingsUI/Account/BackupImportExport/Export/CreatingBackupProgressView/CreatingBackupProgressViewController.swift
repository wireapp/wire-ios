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

import UIKit

final class CreatingBackupProgressViewController: UIViewController {

    var progressDescription = "" {
        didSet { descriptionLabel?.text = progressDescription }
    }

    var progressValue = Float() {
        didSet { progressView?.progress = progressValue }
    }

    var backupURL: URL? {
        didSet { exportButton?.isEnabled = backupURL != nil }
    }

    private var scrollView: UIScrollView! // TODO: lazy?
    private var stackView: UIStackView!
    private var descriptionLabel: UILabel!
    private var progressView: UIProgressView!
    private var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionLabel = .init()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = progressDescription

        progressView = .init(progressViewStyle: .bar)
        progressView.progress = progressValue

        exportButton = .init(type: .system)
        exportButton.setTitle("save", for: .normal)
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        exportButton.isEnabled = backupURL != nil

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

        // TODO: check calculation (e.g. regarding safe area bottom inset)
        let stackViewHeight = stackView.frame.maxY + (navigationController?.navigationBar.frame.height ?? 0)
        if let sheetPresentationController = navigationController?.sheetPresentationController {
            sheetPresentationController.detents = [.custom { _ in stackViewHeight }]
        }
    }

    @objc
    private func showActivityViewController(_ sender: UIButton) {
        guard let backupURL else { return assertionFailure() }

        let activityViewController = UIActivityViewController(activityItems: [backupURL], applicationActivities: nil)
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview
            popoverPresentationController.sourceRect = sender.frame
        }
        present(activityViewController, animated: true)
    }
}
