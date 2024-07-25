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
import WireSyncEngine

final class ChangeEmailViewController: SettingsBaseTableViewController {

    typealias EmailAccountSection = L10n.Localizable.Self.Settings.AccountSection.Email

    fileprivate weak var userProfile = ZMUserSession.shared()?.userProfile
    var state: ChangeEmailState
    private var observerToken: Any?

    let emailCell = AccessoryTextFieldCell(style: .default, reuseIdentifier: nil)

    let userSession: UserSession

    init(user: UserType, userSession: UserSession) {
        self.userSession = userSession
        self.state = ChangeEmailState(currentEmail: user.emailAddress)
        super.init(style: .grouped)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let saveButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: EmailAccountSection.Change.save,
            action: UIAction { [weak self] _ in
                self?.saveButtonTapped()
            })

        saveButtonItem.tintColor = UIColor.accent()
        navigationItem.rightBarButtonItem = saveButtonItem
        setupNavigationBarTitle(EmailAccountSection.Change.title)

        observerToken = userProfile?.add(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = emailCell.textField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observerToken = nil
    }

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

    func updateSaveButtonState(enabled: Bool? = nil) {
        if let enabled {
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = state.isValid
        }
    }

    func saveButtonTapped() {
        requestEmailUpdate(showLoadingView: true)
    }

    func requestEmailUpdate(showLoadingView: Bool) {
        guard let email = state.validatedEmail else { return }

        do {
            try userProfile?.requestEmailChange(email: email)
            updateSaveButtonState(enabled: false)
            navigationController?.isLoadingViewVisible = showLoadingView
        } catch {
            // Handle error
            print("Failed to request email change: \(error)")
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        emailCell.textField.text = state.visibleEmail
        return emailCell
    }
}

extension ChangeEmailViewController: UserProfileUpdateObserver {
    func emailUpdateDidFail(_ error: Error!) {
        navigationController?.isLoadingViewVisible = false
        updateSaveButtonState()
        showAlert(for: error)
    }

    func didSendVerificationEmail() {
        navigationController?.isLoadingViewVisible = false
        updateSaveButtonState()
        if let newEmail = state.newEmail {
            let confirmController = ConfirmEmailViewController(newEmail: newEmail, delegate: self, userSession: userSession)
            navigationController?.pushViewController(confirmController, animated: true)
        }
    }
}

extension ChangeEmailViewController: ConfirmEmailDelegate {
    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        _ = navigationController?.popToPrevious(of: self)
    }

    func resendVerification(inController controller: ConfirmEmailViewController) {
        requestEmailUpdate(showLoadingView: false)
    }
}

extension ChangeEmailViewController: TextFieldValidationDelegate {
    @objc func emailTextFieldEditingChanged(sender: ValidatedTextField) {
        state.newEmail = sender.input.trimmingCharacters(in: .whitespacesAndNewlines)
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        state.emailValidationError = error
        updateSaveButtonState()
    }
}
