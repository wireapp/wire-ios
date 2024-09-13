//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

final class BackupPasswordViewController: UIViewController {
    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias HistoryBackup = L10n.Localizable.Self.Settings.HistoryBackup

    var onCompletion: ((_ password: String?) -> Void)?

    private var password: String?
    private let passwordView = SimpleTextField()

    private let subtitleLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            text: HistoryBackup.Password.description,
            style: .subline1,
            color: LabelColors.textSectionHeader
        )
        label.numberOfLines = 0
        return label
    }()

    private let passwordRulesLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            style: .subline1,
            color: LabelColors.textSectionHeader
        )
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)

        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordView.becomeFirstResponder()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    private func setupViews() {
        view.backgroundColor = ViewColors.backgroundDefault
        passwordRulesLabel.text = PasswordRuleSet.localizedErrorMessage

        for item in [passwordView, subtitleLabel, passwordRulesLabel] {
            view.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        passwordView.placeholder = HistoryBackup.Password.placeholder
        passwordView.accessibilityIdentifier = "password input"
        passwordView.accessibilityHint = PasswordRuleSet.localizedErrorMessage
        passwordView.returnKeyType = .done
        passwordView.isSecureTextEntry = true
        passwordView.delegate = self
        passwordView.textColor = LabelColors.textSectionHeader
        passwordView.backgroundColor = ViewColors.backgroundUserCell
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: SemanticColors.SearchBar.textInputViewPlaceholder,
            .font: UIFont.font(for: .body1),
        ]
        passwordView.updatePlaceholderAttributedText(attributes: attributes)
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            passwordView.heightAnchor.constraint(equalToConstant: 56),
            subtitleLabel.bottomAnchor.constraint(equalTo: passwordView.topAnchor, constant: -16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            passwordRulesLabel.topAnchor.constraint(equalTo: passwordView.bottomAnchor, constant: 16),
            passwordRulesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            passwordRulesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = ViewColors.backgroundDefault

        setupNavigationBarTitle(HistoryBackup.Password.title)

        let cancelButtonItem = UIBarButtonItem.createNavigationLeftBarButtonItem(
            title: HistoryBackup.Password.cancel,
            action: UIAction { [weak self] _ in
                self?.onCompletion?(nil)
            }
        )

        let nextButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: HistoryBackup.Password.next,
            action: UIAction { [weak self] _ in
                self?.onCompletion?(self?.password)
            }
        )

        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false

        navigationItem.leftBarButtonItem = cancelButtonItem
        navigationItem.rightBarButtonItem = nextButtonItem
    }

    private func updateState(with text: String) {
        switch PasswordRuleSet.shared.validatePassword(text) {
        case .valid:
            password = text
            navigationItem.rightBarButtonItem?.isEnabled = true
        case .invalid:
            password = nil
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    @objc
    private dynamic func completeWithCurrentResult() {
        onCompletion?(password)
    }
}

// MARK: - UITextFieldDelegate

extension BackupPasswordViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string.containsCharacters(from: .whitespaces) {
            return false
        }

        if string.containsCharacters(from: .newlines) {
            if password != nil {
                completeWithCurrentResult()
            }
            return false
        }

        let newString = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

        updateState(with: newString)

        return true
    }
}
