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

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()

    var alertTitle: String?
    var alertMessage: String?
    var actions: [UIAlertAction] = []

    // Initializer
    init(title: String?, message: String?) {
        self.alertTitle = title
        self.alertMessage = message
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupContent()
    }

    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        // Container View
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 270)
        ])

        // Stack View
        stackView.axis = .vertical
        stackView.spacing = 8
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
        if let title = alertTitle {
            titleLabel.text = title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            stackView.addArrangedSubview(titleLabel)
        }

        // Message
        if let message = alertMessage {
            messageLabel.text = message
            messageLabel.font = UIFont.systemFont(ofSize: 13)
            messageLabel.textAlignment = .center
            messageLabel.numberOfLines = 0
            stackView.addArrangedSubview(messageLabel)
        }

        // Actions (Buttons)
        for action in actions {
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            button.setTitleColor(action.style == .destructive ? .red : .systemBlue, for: .normal)
            button.addTarget(self, action: #selector(handleAction(_:)), for: .touchUpInside)
            button.tag = actions.firstIndex(of: action) ?? 0
            stackView.addArrangedSubview(button)
        }
    }

    @objc private func handleAction(_ sender: UIButton) {
        let action = actions[sender.tag]
//        action.handler?(action)
        dismiss(animated: true, completion: nil)
    }

    // Add Action Method
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
