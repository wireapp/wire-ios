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
import WireReusableUIComponents
import WireSyncEngine

final class ChangeEmailViewController: SettingsBaseTableViewController {

    // MARK: - Types

    typealias EmailAccountSection = L10n.Localizable.Self.Settings.AccountSection.Email

    // MARK: - Properties

    private let viewModel: ChangeEmailViewModel
    private var observerToken: Any?

    private let emailCell = AccessoryTextFieldCell(style: .default, reuseIdentifier: nil)

    private let userSession: UserSession

    // MARK: - Init

    private lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    init(user: UserType, userSession: UserSession) {
        self.userSession = userSession
        self.viewModel = ChangeEmailViewModel(
            currentEmail: user.emailAddress,
            userProfile: userSession.userProfile
        )
        super.init(style: .grouped)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Override methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let saveButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: EmailAccountSection.Change.save,
            action: UIAction { [weak self] _ in
                self?.saveButtonTapped()
            }
        )

        saveButtonItem.tintColor = UIColor.accent()
        navigationItem.rightBarButtonItem = saveButtonItem
        setupNavigationBarTitle(EmailAccountSection.Change.title)

        observerToken = userSession.userProfile.add(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = emailCell.textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observerToken = nil
    }

    // MARK: - Setup Views

    private func setupViews() {
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false

        emailCell.textField.kind = .email
        emailCell.textField.showConfirmButton = false
        emailCell.textField.backgroundColor = .clear
        emailCell.textField.textColor = SemanticColors.Label.textDefault
        emailCell.textField.accessibilityIdentifier = "EmailField"
        emailCell.textField.textFieldValidationDelegate = self
        emailCell.textField.addTarget(self, action: #selector(emailTextFieldEditingChanged), for: .editingChanged)

        updateSaveButtonState()
    }

    // MARK: - Actions

    func updateSaveButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.isValid
    }

    func saveButtonTapped() {
        requestEmailUpdate()
    }

    func requestEmailUpdate() {
        activityIndicator.setIsActive(true)

        do {
            try viewModel.requestEmailUpdate()
            handleEmailUpdateSuccess()
        } catch {
            activityIndicator.setIsActive(false)
            showAlert(for: error)
        }
    }

    private func handleEmailUpdateSuccess() {
        activityIndicator.setIsActive(false)
        updateSaveButtonState()
        if let newEmail = viewModel.newEmail {
            let confirmController = ConfirmEmailViewController(newEmail: newEmail, delegate: self, userSession: userSession)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }

    // MARK: - SettingsBaseTableViewController

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        emailCell.textField.text = viewModel.visibleEmail
        return emailCell
    }
}

// MARK: - UserProfileUpdateObserver

extension ChangeEmailViewController: UserProfileUpdateObserver {

    func emailUpdateDidFail(_ error: Error!) {
        activityIndicator.stop()
        updateSaveButtonState()
        showAlert(for: error)
    }

    func didSendVerificationEmail() {
        handleEmailUpdateSuccess()
        activityIndicator.stop()
    }
}

// MARK: - ConfirmEmailDelegate

extension ChangeEmailViewController: ConfirmEmailDelegate {
    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        _ = navigationController?.popToPrevious(of: self)
    }

    func resendVerification(inController controller: ConfirmEmailViewController) {
        requestEmailUpdate()
    }
}

// MARK: - TextFieldValidationDelegate

extension ChangeEmailViewController: TextFieldValidationDelegate {
    @objc func emailTextFieldEditingChanged(sender: ValidatedTextField) {
        let newEmail = sender.input.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.updateNewEmail(newEmail)
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        viewModel.updateEmailValidationError(error)
        updateSaveButtonState()
    }
}
