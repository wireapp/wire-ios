//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireLocators

/// This view controller was created because `UIActivityViewController` allows for assigning a
/// `completionWithItemsHandler` closure, which SwiftUI's fileExporter doesn't.
final class CreatingBackupProgressViewController: UIViewController {

    // MARK: State Properties

    var progressDescription = "" {
        didSet {
            guard isViewLoaded else { return }
            descriptionLabel.text = progressDescription
        }
    }

    var progressValues = (current: 0, total: 0) {
        didSet {
            guard isViewLoaded else { return }
            updateProgressValue()
        }
    }

    var backupURL: URL? {
        didSet {
            guard isViewLoaded else { return }
            exportButton.isEnabled = backupURL != nil
        }
    }

    var completedAction: (_ completed: Bool) -> Void = { _ in }

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
        descriptionLabel.accessibilityIdentifier = Locators.CreatingBackupPage.backupCreatedLabel.rawValue
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
        progressLabel.accessibilityIdentifier = "progressLabel"
        return progressLabel
    }()

    private lazy var progressView = {
        let progressView = UIProgressView()
        progressView.accessibilityIdentifier = Locators.CreatingBackupPage.progressView.rawValue
        return progressView
    }()

    private lazy var exportButton = {
        let title = String(localized: "exportBackup.creatingBackup.saveButton.title", bundle: .module)
        let exportButton = UIButton(configuration: .primary, primaryAction: .init(title: title) { _ in })
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        exportButton.accessibilityIdentifier = Locators.CreatingBackupPage.exportBackupButton.rawValue
        return exportButton
    }()

    /// A view which is placed with the optimal bottom spacing.
    /// It's used for calculations of the optimal sheet presentation detent.
    private lazy var bottomSpacer = UIView()

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {

        stackView.setCustomSpacing(4, after: progressLabel)
        stackView.setCustomSpacing(32, after: progressView)

        descriptionLabel.text = progressDescription

        updateProgressValue()

        exportButton.isEnabled = backupURL != nil

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bottomSpacer, at: 0)

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
            svLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            bottomSpacer.heightAnchor.constraint(equalToConstant: 0),
            bottomSpacer.widthAnchor.constraint(equalToConstant: 0),
            bottomSpacer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            view.bottomAnchor.constraint(equalToSystemSpacingBelow: bottomSpacer.bottomAnchor, multiplier: 3)

        ])

        bottomSpacer.backgroundColor = .red

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let navigationController else { return }

        let topSpace = navigationController.view.convert(stackView.bounds, from: stackView).minY
        let stackViewHeight = stackView.frame.height
        let bottomSpace = view.bounds.maxY - bottomSpacer.frame.maxY
        let detent = topSpace + stackViewHeight + bottomSpace
        if let sheetPresentationController = navigationController.sheetPresentationController {
            sheetPresentationController.detents = [.custom { _ in detent }]
        }
    }

    private func updateProgressValue() {
        let progressValue = Float(progressValues.current) / Float(progressValues.total)
        if progressValue.isFinite {
            progressLabel.text = progressValue.formatted(.percent.precision(.fractionLength(0)))
            progressView.progress = progressValue
        } else {
            progressLabel.text = 0.formatted(.percent)
            progressView.progress = 0
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
        activityViewController.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            self?.completedAction(completed)
        }
        present(activityViewController, animated: true)
    }
}
