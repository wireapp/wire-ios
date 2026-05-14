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
import WireDataModel
import WireSettingsUI
import WireSyncEngine

// MARK: - ConfirmEmailDelegate

protocol ConfirmEmailDelegate: AnyObject {
    func resendVerification(inController controller: ConfirmEmailViewController)
    func didConfirmEmail(inController controller: ConfirmEmailViewController)
}

struct ConfirmEmailViewControllerBuilder {

    private let newEmail: String
    private let delegate: ConfirmEmailDelegate?
    private let userSession: UserSession
    private let useTypeIntrinsicSizeTableView: Bool
    private let settingsCoordinator: AnySettingsCoordinator
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        newEmail: String,
        delegate: ConfirmEmailDelegate?,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.newEmail = newEmail
        self.delegate = delegate
        self.userSession = userSession
        self.useTypeIntrinsicSizeTableView = useTypeIntrinsicSizeTableView
        self.settingsCoordinator = settingsCoordinator
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    func build() -> ConfirmEmailViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation()
        }

        return buildLegacy()
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .confirmEmail,
            isKMPImplementationAvailable: false
        )
    }

    private func buildKMPViewModelImplementation() -> ConfirmEmailViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy()
    }

    private func buildLegacy() -> ConfirmEmailViewController {
        ConfirmEmailViewController(
            newEmail: newEmail,
            delegate: delegate,
            userSession: userSession,
            useTypeIntrinsicSizeTableView: useTypeIntrinsicSizeTableView,
            settingsCoordinator: settingsCoordinator
        )
    }
}

// MARK: - UITableView extension

extension UITableView {
    var autolayoutTableHeaderView: UIView? {
        get {
            tableHeaderView
        }

        set {
            if let newHeader = newValue {
                newHeader.translatesAutoresizingMaskIntoConstraints = false

                tableHeaderView = newHeader

                NSLayoutConstraint.activate([
                    newHeader.centerXAnchor.constraint(equalTo: centerXAnchor),
                    newHeader.widthAnchor.constraint(equalTo: widthAnchor),
                    newHeader.topAnchor.constraint(equalTo: topAnchor)
                ])

                tableHeaderView?.layoutIfNeeded()
                tableHeaderView = newHeader
            } else {
                tableHeaderView = nil
            }
        }
    }
}

// MARK: - ConfirmEmailViewController

final class ConfirmEmailViewController: SettingsBaseTableViewController {

    // MARK: - Properties

    weak var delegate: ConfirmEmailDelegate?
    private let viewModel: ConfirmEmailViewModel
    let userSession: UserSession
    fileprivate var observer: NSObjectProtocol?

    // MARK: - Init

    init(
        newEmail: String,
        delegate: ConfirmEmailDelegate?,
        userSession: UserSession,
        useTypeIntrinsicSizeTableView: Bool,
        settingsCoordinator: AnySettingsCoordinator
    ) {
        self.viewModel = ConfirmEmailViewModel(newEmail: newEmail)
        self.delegate = delegate
        self.userSession = userSession
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
        super.viewDidAppear(animated)
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        observer = userSession.addUserObserver(self, for: selfUser)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observer = nil
    }

    // MARK: - Override methods

    func setupViews() {
        SettingsButtonCell.register(in: tableView)
        let displayState = viewModel.displayState

        title = displayState.title
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 30

        let description = DescriptionHeaderView()
        description.descriptionLabel.text = displayState.description

        tableView.autolayoutTableHeaderView = description
    }

    // MARK: - Setup tableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsButtonCell.zm_reuseIdentifier,
            for: indexPath
        ) as! SettingsButtonCell
        cell.titleText = viewModel.displayState.resendButtonTitle
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resendVerification(inController: self)
        tableView.deselectRow(at: indexPath, animated: false)

        let action = viewModel.resendButtonTapped()
        let confirmation: ConfirmEmailViewModel.ResendConfirmation
        switch action {
        case let .resendVerification(resendConfirmation):
            confirmation = resendConfirmation
        }

        let alert = UIAlertController(
            title: confirmation.title,
            message: confirmation.message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: confirmation.buttonTitle, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - ZMUserObserving

extension ConfirmEmailViewController: UserObserving {
    func userDidChange(_ note: WireDataModel.UserChangeInfo) {
        if note.user.isSelfUser {
            // we need to check if the notification really happened because
            // the email got changed to what we expected
            guard let selfUser = ZMUser.selfUser() else {
                assertionFailure("ZMUser.selfUser() is nil")
                return
            }

            if viewModel.routeForObservedEmailChange(
                isSelfUser: note.user.isSelfUser,
                currentEmail: selfUser.emailAddress
            ) == .confirmedEmail {
                delegate?.didConfirmEmail(inController: self)
            }
        }
    }
}
