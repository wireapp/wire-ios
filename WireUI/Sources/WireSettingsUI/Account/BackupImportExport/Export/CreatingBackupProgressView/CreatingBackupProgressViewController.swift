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
import WireDesign

final class CreatingBackupProgressViewController: UIViewController {

    // MARK: State Properties

    var progressDescription = "" {
        didSet {
            guard isViewLoaded else { return }
            descriptionLabel.text = progressDescription
        }
    }

    var progressValue = Float() {
        didSet {
            guard isViewLoaded else { return }
            progressView.progress = progressValue
            progressLabel.text = "\(Int(progressValue * 100))%"
        }
    }

    var backupURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            exportButton.isEnabled = backupURL != nil
        }
    }

    // MARK: - Subviews

    private lazy var scrollView = UIScrollView()

    private lazy var stackView = {
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel, progressLabel, progressView, exportButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    private var descriptionLabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .preferredFont(forTextStyle: .caption1)
        descriptionLabel.textColor = BaseColorPalette.Grays.gray70
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.accessibilityIdentifier = "" // TODO: [WPB-15466] fix accessibility
        descriptionLabel.accessibilityLabel = "" // TODO: [WPB-15466] fix accessibility
        return descriptionLabel
    }()

    private lazy var progressLabel = {
        let progressLabel = UILabel()
        let font = UIFont.preferredFont(forTextStyle: .caption2)
        let fontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
        progressLabel.font = .init(descriptor: fontDescriptor ?? font.fontDescriptor, size: 0)
        progressLabel.adjustsFontForContentSizeCategory = true
        progressLabel.textColor = BaseColorPalette.Grays.gray70
        progressLabel.textAlignment = .center
        progressLabel.accessibilityIdentifier = "" // TODO: [WPB-15466] fix accessibility
        progressLabel.accessibilityLabel = "" // TODO: [WPB-15466] fix accessibility
        return progressLabel
    }()

    private lazy var progressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = ColorTheme.Base.primary
        progressView.accessibilityIdentifier = "" // TODO: [WPB-15466] fix accessibility
        progressView.accessibilityLabel = "" // TODO: [WPB-15466] fix accessibility
        return progressView
    }()

    private lazy var exportButton = {
        let title = String(localized: "creatingBackup.saveFileButton.title", bundle: .module)
        let exportButton = UIButton()
        exportButton.wireButtonStyle = .primary
        exportButton.setTitle(title, for: .normal)
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        exportButton.accessibilityIdentifier = "" // TODO: [WPB-15466] fix accessibility
        exportButton.accessibilityLabel = "" // TODO: [WPB-15466] fix accessibility
        return exportButton
    }()

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {

        stackView.setCustomSpacing(4, after: progressLabel)
        stackView.setCustomSpacing(32, after: progressView)

        descriptionLabel.text = progressDescription

        progressLabel.text = "\(Int(progressValue * 100))%"

        progressView.progress = progressValue

        exportButton.isEnabled = backupURL != nil

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        // constraints
        let svLayoutGuide = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: svLayoutGuide.leadingAnchor, multiplier: 3),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: svLayoutGuide.topAnchor, multiplier: 1),
            svLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 3),
            svLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)

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
