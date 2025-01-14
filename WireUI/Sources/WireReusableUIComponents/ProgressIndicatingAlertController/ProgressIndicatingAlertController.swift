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

import WireDesign
import UIKit

/// A custom view controller which displays an alert-like interface with a progress bar and a cancel button.
public final class ProgressIndicatingAlertController: UIViewController {

    // MARK: - Properties

    public var progress = Float() {
        didSet {
            progressLabel.text = "\(Int(progress * 100))%"
            progressView.progress = progress
        }
    }

    private let message: String
    private let cancelAction: Action

    // MARK: - Subviews

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView()
    private let cancelButton = UIButton(type: .system)

    // MARK: - Initializer

    init(
        title: String,
        message: String,
        cancelAction: Action
    ) {
        self.message = message
        self.cancelAction = cancelAction
        super.init(nibName: nil, bundle: nil)
        self.title = title

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundDimming()
        setupContainerView()
        setupContent()
    }

    // MARK: - Private Setup Methods

    private func setupBackgroundDimming() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2) // TODO: test dark mode
    }

    private func setupContainerView() {
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 270)
        ])
    }

    private func setupContent() {
        titleLabel.text = title
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        messageLabel.text = message
        messageLabel.font = .preferredFont(forTextStyle: .caption1)
        messageLabel.textColor = BaseColorPalette.Grays.gray70
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        progressLabel.text = "\(Int(progress * 100))%"
        progressLabel.font = .preferredFont(forTextStyle: .caption1)
        progressLabel.textColor = BaseColorPalette.Grays.gray70
        progressLabel.textAlignment = .center
        progressLabel.numberOfLines = 1
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressLabel)

        progressView.progressViewStyle = .bar
        progressView.progress = progress
        progressView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressView)

        cancelButton.setTitle("Cancel", for: .normal) // TODO: localization
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        cancelButton.addTarget(self, action: #selector(handleCancel(_:)), for: .primaryActionTriggered)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: containerView.leadingAnchor, multiplier: 2),
            titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: containerView.topAnchor, multiplier: 2.5),
            containerView.trailingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 2),

            messageLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            messageLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1),
            titleLabel.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor),

            progressLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressLabel.topAnchor.constraint(equalToSystemSpacingBelow: messageLabel.bottomAnchor, multiplier: 1),

            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            progressView.topAnchor.constraint(equalToSystemSpacingBelow: progressLabel.bottomAnchor, multiplier: 1),
            containerView.trailingAnchor.constraint(equalTo: progressView.trailingAnchor),

            cancelButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            cancelButton.topAnchor.constraint(equalToSystemSpacingBelow: progressView.bottomAnchor, multiplier: 1),
            titleLabel.trailingAnchor.constraint(equalTo: cancelButton.trailingAnchor),
            containerView.bottomAnchor.constraint(equalToSystemSpacingBelow: cancelButton.bottomAnchor, multiplier: 1),
        ])
    }

    // MARK: - Action Handling

    @objc private func handleCancel(_ sender: UIButton) {
        cancelAction.handler()
        presentingViewController?.dismiss(animated: true)
    }

    // MARK: - Nested Types

    struct Action {
        var title: String
        var handler: () -> Void
    }
}

@available(iOS 17, *)
#Preview("ProgressIndicatingAlertController") {
    ProgressIndicatingAlertControllerPreview()
}

@available(iOS 17, *)
#Preview("UIAlertController") {
    {
        let vc = UIViewController()
        vc.navigationItem.title = "test"

        let label = UILabel()
        label.text = "Hello, World!"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        vc.view.addSubview(label)
        label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor).isActive = true
        label.topAnchor.constraint(equalToSystemSpacingBelow: vc.view.safeAreaLayoutGuide.topAnchor, multiplier: 3).isActive = true

        let alertController = UIAlertController(title: "title", message: "message", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        alertController.addAction(cancelAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            vc.present(alertController, animated: false)
        }

        return UINavigationController(rootViewController: vc)
    }()
}
