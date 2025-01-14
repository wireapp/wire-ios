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

/// A custom view controller that displays an alert-like interface.
public final class ProgressIndicatingAlertController: UIViewController {

    /// A custom action model that mimics UIAlertAction.
    struct CustomAlertAction {
        /// The button title shown in the alert.
        let title: String

        /// The style for the button (default, cancel, or destructive).
        let style: UIAlertAction.Style

        /// The closure to execute when the button is tapped.
        let handler: ((CustomAlertAction) -> Void)?
    }

    // MARK: - UI Elements

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    /// A stack view to layout the title, message, and buttons vertically.
    private let stackView = UIStackView()

    // MARK: - Properties

    /// The alert's title and message text.
    private let alertTitle: String?
    private let alertMessage: String?

    /// An array of custom actions that will be turned into buttons.
    private var actions: [CustomAlertAction] = []

    // MARK: - Initializer

    init(title: String?, message: String?) {
        self.alertTitle = title
        self.alertMessage = message
        super.init(nibName: nil, bundle: nil)

        // Presentation style to mimic a system alert (centered, dim background).
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupBackgroundDimming()
        setupContainerView()
        setupStackView()
        setupContent()  // Populate with title, message, and buttons.
    }

    // MARK: - Public Methods

    /// Add a custom action to the alert.
    func addAction(_ action: CustomAlertAction) {
        actions.append(action)
    }

    // MARK: - Private Setup Methods

    private func setupBackgroundDimming() {
        // Dim the background to mimic a system alert’s overlay.
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    }

    private func setupContainerView() {
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerView)

        // Center the container and set its width (similar to UIAlertController).
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 270)
        ])
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)

        // Pin stackView edges to containerView with some padding.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func setupContent() {
        // 1. Title
        if let alertTitle = alertTitle {
            titleLabel.text = alertTitle
//            titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
            titleLabel.textColor = .label
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            titleLabel.adjustsFontForContentSizeCategory = true
            stackView.addArrangedSubview(titleLabel)
        }

        // 2. Message
        if let alertMessage = alertMessage {
            messageLabel.text = alertMessage
            messageLabel.font = UIFont.systemFont(ofSize: 13)
            messageLabel.textColor = .secondaryLabel
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stackView.addArrangedSubview(messageLabel)
        }

        // 3. Buttons (one for each CustomAlertAction)
        for (index, action) in actions.enumerated() {
            // Add a thin separator above each button (optional, for clarity).
            if stackView.arrangedSubviews.count > 0 {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                stackView.addArrangedSubview(separator)
            }

            // Create a button for the action.
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
//            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            // Use a preferred font style for buttons, e.g. .body or .callout
                 button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
                 button.titleLabel?.adjustsFontForContentSizeCategory = true

            // Match the color style of system alerts.
            switch action.style {
            case .destructive:
                button.setTitleColor(.systemRed, for: .normal)
            case .cancel:
                button.setTitleColor(.systemBlue, for: .normal)
                button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17) // TODO: dynamic type
            default:
                button.setTitleColor(.systemBlue, for: .normal)
            }

            // Tag to identify which action was tapped.
            button.tag = index
            button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)

            // Add the button to the stack.
            stackView.addArrangedSubview(button)
        }
    }

    // MARK: - Action Handling

    @objc private func handleButtonTap(_ sender: UIButton) {
        let tappedAction = actions[sender.tag]

        // Call the custom handler closure.
        tappedAction.handler?(tappedAction)

        // Dismiss the custom alert.
        dismiss(animated: true, completion: nil)
    }
}

@available(iOS 17, *)
#Preview("ProgressIndicatingAlertController") {
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

        let alertController = ProgressIndicatingAlertController(title: "title", message: "message")

        let cancelAction = ProgressIndicatingAlertController.CustomAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel button tapped!")
            // Add any additional cleanup or logic here
        }
        alertController.addAction(cancelAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            vc.present(alertController, animated: false)
        }

        return UINavigationController(rootViewController: vc)
    }()
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

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("Cancel button tapped!")
            // Add any additional cleanup or logic here
        }
        alertController.addAction(cancelAction)

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
            vc.present(alertController, animated: false)
        }

        return UINavigationController(rootViewController: vc)
    }()
}
