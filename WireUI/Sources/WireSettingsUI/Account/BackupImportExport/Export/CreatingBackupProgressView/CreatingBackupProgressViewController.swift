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
        let stackView = UIStackView(arrangedSubviews: [descriptionLabel, progressView, exportButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()

    private var descriptionLabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        return descriptionLabel
    }()

    private lazy var progressView = UIProgressView(progressViewStyle: .bar)

    private var exportButton: UIButton!
    private var exportButton_: UIView!

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {

        descriptionLabel.text = progressDescription

        progressView.progress = progressValue

        exportButton = .init(type: .system)
        exportButton.setTitle("save", for: .normal)
        exportButton.addTarget(self, action: #selector(showActivityViewController(_:)), for: .primaryActionTriggered)
        exportButton.isEnabled = backupURL != nil

        exportButton_ = WireButtonStyleButton(addedTo: view, of: self)
        exportButton_.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(exportButton_)

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
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: svLayoutGuide.topAnchor, multiplier: 3),
            svLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 3),
            svLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 3)

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

/// Embeds a SwiftUI Button with a `.wireButtonStyle` modifier using a `UIHostingController`.
/// The button view will be added as subview, the hosting controller will be added as child view controller.
/// - Parameters:
///   - view: Any view within the `viewController`'s view hierarchy.
///   - viewController: A view controller which contains the `view`.
/// - Returns: The hosting controller's view.
@MainActor
private func WireButtonStyleButton(addedTo view: UIView, of viewController: UIViewController) -> UIView {
    let hostingController = UIHostingController(
        rootView: Button("Tap me") {
            print("tap")
        }.wireButtonStyle(.primary)
    )
    viewController.addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.didMove(toParent: viewController)
    return hostingController.view
}
