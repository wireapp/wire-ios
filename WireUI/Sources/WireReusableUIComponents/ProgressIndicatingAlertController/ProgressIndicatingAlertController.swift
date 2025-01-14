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

public final class ProgressIndicatingAlertController: UIViewController {

    struct Action {
        let title: String
        let style: UIAlertAction.Style
        let handler: (() -> Void)?
    }

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()

    var alertTitle: String?
    var alertMessage: String?
    var actions: [Action] = []

    // Initializer
    init(title: String?, message: String?) {
        self.alertTitle = title
        self.alertMessage = message
        super.init(nibName: nil, bundle: nil)

        // Presentation style to mimic an alert
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupContainerView()
        setupStackView()
        setupContent()
    }

    // MARK: - Setup Methods

    private func setupBackground() {
        // Dim the background to mimic an alert
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
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

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func setupContent() {
        // Title
        if let titleText = alertTitle {
            titleLabel.text = titleText
            titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            titleLabel.adjustsFontForContentSizeCategory = true
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0

            stackView.addArrangedSubview(titleLabel)
        }

        // Message
        if let messageText = alertMessage {
            messageLabel.text = messageText
            messageLabel.font = UIFont.preferredFont(forTextStyle: .body)
            messageLabel.adjustsFontForContentSizeCategory = true
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0

            stackView.addArrangedSubview(messageLabel)
        }

        // Actions (Buttons)
        for action in actions {
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)

            // Use a preferred font style for buttons, e.g. .body or .callout
            button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            button.titleLabel?.adjustsFontForContentSizeCategory = true

            switch action.style {
            case .destructive:
                button.setTitleColor(.systemRed, for: .normal)
            default:
                button.setTitleColor(.systemBlue, for: .normal)
            }

            // Tag each button so we know which action to trigger
            button.tag = actions.firstIndex(of: action) ?? 0
            button.addTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)

            // Add a separator for clarity if you like
            // (Or you can just add the button if you don't need separators)
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false

            // If you want a thin line above each button (optional):
            if stackView.arrangedSubviews.last != nil {
                let separatorContainer = UIView()
                separatorContainer.addSubview(separator)
                NSLayoutConstraint.activate([
                    separator.leadingAnchor.constraint(equalTo: separatorContainer.leadingAnchor),
                    separator.trailingAnchor.constraint(equalTo: separatorContainer.trailingAnchor),
                    separator.topAnchor.constraint(equalTo: separatorContainer.topAnchor),
                    separator.heightAnchor.constraint(equalToConstant: 0.5),
                    separatorContainer.heightAnchor.constraint(equalToConstant: 0.5)
                ])
                stackView.addArrangedSubview(separatorContainer)
            }

            stackView.addArrangedSubview(button)
        }
    }

    // MARK: - Action Handling

    @objc private func handleAction(_ sender: UIButton) {
        let action = actions[sender.tag]
        action?(action)
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Public Methods

    func addAction(_ action: UIAlertAction) {
        actions.append(action)
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
