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
import WireReusableUIComponents
import WireSettingsUI
import WireSyncEngine

struct ChangeEmailViewControllerBuilder {

    private let user: UserType
    private let userSession: UserSession
    private let useTypeIntrinsicSizeTableView: Bool
    private let settingsCoordinator: AnySettingsCoordinator
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        user: UserType,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.user = user
        self.userSession = userSession
        self.useTypeIntrinsicSizeTableView = useTypeIntrinsicSizeTableView
        self.settingsCoordinator = settingsCoordinator
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    func build() -> ChangeEmailViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation()
        }

        return buildLegacy()
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .changeEmail,
            isKMPImplementationAvailable: false
        )
    }

    private func buildKMPViewModelImplementation() -> ChangeEmailViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy()
    }

    private func buildLegacy() -> ChangeEmailViewController {
        ChangeEmailViewController(
            user: user,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator,
            kmpViewModelEnvironment: kmpViewModelEnvironment
        )
    }
}

final class ChangeEmailViewController: SettingsBaseTableViewController {

    // MARK: - Types

    typealias EmailAccountSection = L10n.Localizable.Self.Settings.AccountSection.Email

    // MARK: - Properties

    private let viewModel: ChangeEmailViewModel
    private var observerToken: Any?

    private let emailCell = AccessoryTextFieldCell(style: .default, reuseIdentifier: nil)

    private let userSession: UserSession
    private let kmpViewModelEnvironment: KMPViewModelEnvironment?

    // MARK: - Init

    private lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    init(
        user: UserType,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        kmpViewModelEnvironment: KMPViewModelEnvironment? = nil
    ) {
        self.userSession = userSession
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
        self.viewModel = ChangeEmailViewModel(
            currentEmail: user.emailAddress,
            userProfile: userSession.userProfile
        )
        super.init(
            style: .grouped,
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator
        )
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
        saveButtonItem.accessibilityIdentifier = Locators.EmailUpdatePage.save.rawValue
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
        emailCell.textField.accessibilityIdentifier = Locators.EmailUpdatePage.emailField.rawValue
        emailCell.textField.textFieldValidationDelegate = self
        emailCell.textField.addTarget(self, action: #selector(emailTextFieldEditingChanged), for: .editingChanged)

        render(viewModel.displayState)
    }

    // MARK: - Actions

    func render(_ displayState: ChangeEmailViewModel.DisplayState) {
        navigationItem.rightBarButtonItem?.isEnabled = displayState.isSaveButtonEnabled
    }

    func saveButtonTapped() {
        handle(viewModel.saveButtonTapped())
    }

    func requestEmailUpdate() {
        activityIndicator.setIsActive(true)

        do {
            let route = try viewModel.requestEmailUpdate()
            handleEmailUpdateSuccess(route: route)
        } catch {
            activityIndicator.setIsActive(false)
            handle(viewModel.actionForEmailUpdateFailure(error))
        }
    }

    private func handleEmailUpdateSuccess(route: ChangeEmailViewModel.Route?) {
        activityIndicator.setIsActive(false)
        render(viewModel.displayState)
        handle(route)
    }

    private func handle(_ action: ChangeEmailViewModel.Action) {
        switch action {
        case .requestEmailUpdate:
            requestEmailUpdate()
        case let .showAlert(error):
            showAlert(for: error)
        }
    }

    private func handle(_ route: ChangeEmailViewModel.Route?) {
        switch route {
        case let .confirmEmail(newEmail):
            let confirmController = buildConfirmEmailController(newEmail: newEmail)
            navigationController?.pushViewController(confirmController, animated: true)
        case .none:
            break
        }
    }

    private func buildConfirmEmailController(newEmail: String) -> ConfirmEmailViewController {
        guard let kmpViewModelEnvironment else {
            return ConfirmEmailViewController(
                newEmail: newEmail,
                delegate: self,
                userSession: userSession,
                useTypeIntrinsicSizeTableView: true,
                settingsCoordinator: settingsCoordinator
            )
        }

        return ConfirmEmailViewControllerBuilder(
            newEmail: newEmail,
            delegate: self,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: true,
            settingsCoordinator: settingsCoordinator,
            kmpViewModelEnvironment: kmpViewModelEnvironment
        ).build()
    }

    // MARK: - SettingsBaseTableViewController

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        emailCell.textField.text = viewModel.displayState.visibleEmail
        return emailCell
    }
}

// MARK: - UserProfileUpdateObserver

extension ChangeEmailViewController: UserProfileUpdateObserver {

    func emailUpdateDidFail(_ error: Error!) {
        activityIndicator.stop()
        render(viewModel.displayState)
        handle(viewModel.actionForEmailUpdateFailure(error))
    }

    func didSendVerificationEmail() {
        handleEmailUpdateSuccess(route: viewModel.routeForEmailUpdateSuccess())
        activityIndicator.stop()
    }
}

// MARK: - ConfirmEmailDelegate

extension ChangeEmailViewController: ConfirmEmailDelegate {

    func didConfirmEmail(inController controller: ConfirmEmailViewController) {
        let viewControllers = navigationController?.viewControllers ?? []
        if let index = viewControllers.firstIndex(of: self), viewControllers.indices.contains(index - 1) {
            let previousController = viewControllers[index - 1]
            navigationController?.popToViewController(previousController, animated: true)
        }
    }

    func resendVerification(inController controller: ConfirmEmailViewController) {
        requestEmailUpdate()
    }
}

// MARK: - TextFieldValidationDelegate

extension ChangeEmailViewController: TextFieldValidationDelegate {
    @objc
    func emailTextFieldEditingChanged(sender: ValidatedTextField) {
        viewModel.updateNewEmail(sender.input)
        sender.validateInput()
    }

    func validationUpdated(sender: UITextField, error: TextFieldValidator.ValidationError?) {
        render(viewModel.displayState)
    }
}
