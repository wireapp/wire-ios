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

final class ProxyCredentialsViewController: UIViewController {

    let backendURL: URL
    let viewModel: ProxyCredentialsViewModel

    var textFieldDidUpdateText: (ValidatedTextField) -> Void
    var activeFieldChange: (UITextField?) -> Void

    init(
        backendURL: URL,
        viewModel: ProxyCredentialsViewModel? = nil,
        textFieldDidUpdateText: @escaping (ValidatedTextField) -> Void,
        activeFieldChange: @escaping (UITextField?) -> Void
    ) {
        self.backendURL = backendURL
        self.viewModel = viewModel ?? ProxyCredentialsViewModel(backendURL: backendURL)
        self.textFieldDidUpdateText = textFieldDidUpdateText
        self.activeFieldChange = activeFieldChange
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var titleLabel = {
        let label = DynamicFontLabel(
            text: viewModel.displayState.title,
            style: .h3,
            color: SemanticColors.Label.textCellSubtitle
        )
        label.text = viewModel.displayState.title
        return label
    }()

    lazy var captionLabel = {
        let label = DynamicFontLabel(
            text: viewModel.displayState.caption,
            style: .body1,
            color: SemanticColors.Label.textCellSubtitle
        )
        label.numberOfLines = 0
        return label
    }()

    lazy var usernameInput: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .email,
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 0,
            style: .default
        )
        textField.showConfirmButton = false
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: .uppercased() when new design is implemented
        textField.placeholder = viewModel.displayState.usernamePlaceholder
        textField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        textField.delegate = self
        textField.addDoneButtonOnKeyboard()
        return textField
    }()

    lazy var passwordInput: ValidatedTextField = {
        let textField = ValidatedTextField(
            kind: .password(.nonEmpty, isNew: false),
            leftInset: 8,
            accessoryTrailingInset: 0,
            cornerRadius: 0,
            style: .default
        )

        // swiftlint:disable:next todo_requires_jira_link
        // TODO: .uppercased() when new design is implemented
        textField.placeholder = viewModel.displayState.passwordPlaceholder
        textField.addTarget(self, action: #selector(textInputDidChange), for: .editingChanged)
        textField.delegate = self
        textField.addDoneButtonOnKeyboard()
        textField.returnKeyType = .done
        textField.addRevealButton(delegate: self)
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyDisplayState(viewModel.displayState)

        let separator: () -> UIView = {
            let view = UIView()
            view.backgroundColor = SemanticColors.View.backgroundSeparatorCell
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)
            view.heightAnchor.constraint(equalToConstant: 1).isActive = true

            view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true

            return view
        }

        let topSeparator = separator()
        let bottomSeparator = separator()

        [
            titleLabel,
            captionLabel,
            usernameInput,
            passwordInput
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview($0)

            let margin: CGFloat = 31
            $0.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin).isActive = true
        }

        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: view.topAnchor),

            titleLabel.topAnchor.constraint(equalTo: topSeparator.bottomAnchor, constant: 30),
            captionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            usernameInput.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 30),
            passwordInput.topAnchor.constraint(equalTo: usernameInput.bottomAnchor, constant: 36),

            bottomSeparator.topAnchor.constraint(equalTo: passwordInput.bottomAnchor, constant: 26),
            bottomSeparator.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),

            usernameInput.heightAnchor.constraint(equalToConstant: 48),
            passwordInput.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc
    private func textInputDidChange(sender: ValidatedTextField) {
        if sender == usernameInput {
            applyDisplayState(viewModel.update(.username, text: sender.input))
        } else if sender == passwordInput {
            applyDisplayState(viewModel.update(.password, text: sender.input))
        }

        textFieldDidUpdateText(sender)
    }

    private func applyDisplayState(_ displayState: ProxyCredentialsViewModel.DisplayState) {
        titleLabel.text = displayState.title
        captionLabel.text = displayState.caption
        if usernameInput.text != displayState.username {
            usernameInput.text = displayState.username
        }
        if passwordInput.text != displayState.password {
            passwordInput.text = displayState.password
        }
        usernameInput.placeholder = displayState.usernamePlaceholder
        passwordInput.placeholder = displayState.passwordPlaceholder
    }
}

extension ProxyCredentialsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameInput {
            passwordInput.becomeFirstResponder()
        } else if textField == passwordInput {
            textField.resignFirstResponder()
            applyDisplayState(viewModel.update(.password, text: passwordInput.input))
            textFieldDidUpdateText(passwordInput)
        }
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeFieldChange(textField)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeFieldChange(nil)
    }

}

extension ProxyCredentialsViewController: ValidatedTextFieldDelegate {
    func buttonPressed(_ sender: UIButton) {
        passwordInput.isSecureTextEntry.toggle()
        passwordInput.updatePasscodeIcon()
    }
}
