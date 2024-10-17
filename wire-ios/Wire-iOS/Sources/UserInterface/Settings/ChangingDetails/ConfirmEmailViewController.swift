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
import WireDataModel
import WireSettingsUI
import WireSyncEngine

// MARK: - ConfirmEmailDelegate

protocol ConfirmEmailDelegate: AnyObject {
    func resendVerification(inController controller: ConfirmEmailViewController)
    func didConfirmEmail(inController controller: ConfirmEmailViewController)
}

// MARK: - UITableView extension

extension UITableView {
    var autolayoutTableHeaderView: UIView? {
        get {
            return self.tableHeaderView
        }

        set {
            if let newHeader = newValue {
                newHeader.translatesAutoresizingMaskIntoConstraints = false

                self.tableHeaderView = newHeader

                NSLayoutConstraint.activate([
                    newHeader.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    newHeader.widthAnchor.constraint(equalTo: self.widthAnchor),
                    newHeader.topAnchor.constraint(equalTo: self.topAnchor)
                ])

                self.tableHeaderView?.layoutIfNeeded()
                self.tableHeaderView = newHeader
            } else {
                self.tableHeaderView = nil
            }
        }
    }
}

// MARK: - ConfirmEmailViewController

final class ConfirmEmailViewController: SettingsBaseTableViewController {

    // MARK: - Properties

    weak var delegate: ConfirmEmailDelegate?
    typealias SettingsAccountSectionEmailLocalizable = L10n.Localizable.Self.Settings.AccountSection.Email.Change
    let newEmail: String
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
        self.newEmail = newEmail
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

        title = SettingsAccountSectionEmailLocalizable.Verify.title
        view.backgroundColor = .clear
        tableView.isScrollEnabled = false

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 30

        let description = DescriptionHeaderView()
        description.descriptionLabel.text = SettingsAccountSectionEmailLocalizable.Verify.description

        tableView.autolayoutTableHeaderView = description
    }

    // MARK: - Setup tableView

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsButtonCell.zm_reuseIdentifier, for: indexPath) as! SettingsButtonCell
        let text = SettingsAccountSectionEmailLocalizable.Verify.resend(newEmail)
        cell.titleText = text
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.resendVerification(inController: self)
        tableView.deselectRow(at: indexPath, animated: false)

        let message = SettingsAccountSectionEmailLocalizable.Resend.message(newEmail)

        let alert = UIAlertController(
            title: SettingsAccountSectionEmailLocalizable.Resend.title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: L10n.Localizable.General.ok, style: .cancel, handler: nil))
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

            if let currentEmail = selfUser.emailAddress, currentEmail == newEmail {
                delegate?.didConfirmEmail(inController: self)
            }
        }
    }
}
