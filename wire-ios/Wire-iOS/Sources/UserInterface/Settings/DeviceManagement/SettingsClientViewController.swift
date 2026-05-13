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
import WireReusableUIComponents
import WireSyncEngine

final class SettingsClientViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    UserClientObserver,
    ClientColorVariantProtocol {

    private static let deleteCellReuseIdentifier: String = "DeleteCellReuseIdentifier"
    private static let resetCellReuseIdentifier: String = "ResetCellReuseIdentifier"
    private static let verifiedCellReuseIdentifier: String = "VerifiedCellReuseIdentifier"

    let userSession: UserSession
    let viewModel: SettingsClientViewModel
    var userClient: UserClient {
        viewModel.userClient
    }

    var userClientToken: NSObjectProtocol!
    var credentials: UserEmailCredentials?

    var tableView: UITableView!
    let topSeparator = OverflowSeparatorView()

    var fromConversation: Bool = false

    var removalObserver: ClientRemovalObserver?

    private lazy var activityIndicator = BlockingActivityIndicator(view: view)

    convenience init(
        userClient: UserClient,
        userSession: UserSession,
        fromConversation: Bool,
        credentials: UserEmailCredentials? = .none
    ) {
        self.init(userClient: userClient, userSession: userSession, credentials: credentials)
        self.fromConversation = fromConversation
    }

    required init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: UserEmailCredentials? = .none
    ) {
        self.userSession = userSession
        self.viewModel = SettingsClientViewModel(
            userClient: userClient,
            selfUserClient: userSession.selfUserClient,
            getUserClientFingerprint: userSession.getUserClientFingerprint
        )
        super.init(nibName: nil, bundle: nil)
        self.userClientToken = UserClientChangeInfo.add(observer: self, for: userClient)

        viewModel.fingerprintDataClosure = { [weak self] _ in
            self?.tableView.reloadData()
        }

        self.credentials = credentials
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(topSeparator)
        createTableView()
        createConstraints()

        if fromConversation {
            setupFromConversationStyle()
        }
        setColor()

        viewModel.loadData()
    }

    func setupFromConversationStyle() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func setupNavigationTitle() {
        guard let title = viewModel.navigationTitle else { return }
        setupNavigationBarTitle(title)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationTitle()
        // presented modally from conversation
        if let navController = navigationController,
           !navController.viewControllers.isEmpty,
           navController.viewControllers[0] == self,
           navigationItem.rightBarButtonItem == nil {

            let doneButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
                title: L10n.Localizable.General.done,
                action: UIAction { [weak self] _ in
                    self?.navigationController?.presentingViewController?.dismiss(animated: true)
                }
            )

            navigationItem.rightBarButtonItem = doneButtonItem
            if fromConversation {
                let barColor = SemanticColors.View.backgroundDefault
                navController.navigationBar.barTintColor = barColor
            }
        }
    }

    private func createTableView() {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .none
        tableView.register(ClientTableViewCell.self, forCellReuseIdentifier: ClientTableViewCell.zm_reuseIdentifier)
        tableView.register(
            FingerprintTableViewCell.self,
            forCellReuseIdentifier: FingerprintTableViewCell.zm_reuseIdentifier
        )
        tableView.register(SettingsTableCell.self, forCellReuseIdentifier: type(of: self).deleteCellReuseIdentifier)
        tableView.register(SettingsTableCell.self, forCellReuseIdentifier: type(of: self).resetCellReuseIdentifier)
        tableView.register(SettingsToggleCell.self, forCellReuseIdentifier: type(of: self).verifiedCellReuseIdentifier)
        self.tableView = tableView
        view.addSubview(tableView)
    }

    private func createConstraints() {
        [tableView, topSeparator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),

            topSeparator.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            topSeparator.rightAnchor.constraint(equalTo: tableView.rightAnchor),
            topSeparator.topAnchor.constraint(equalTo: tableView.topAnchor)
        ])
    }

    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func onVerifiedChanged(_ sender: UISwitch!) {
        let selfClient = userSession.selfUserClient
        let action = viewModel.actionForVerifiedChanged(isOn: sender.isOn)

        userSession.enqueue {
            switch action {
            case let .setVerified(userClient, isVerified):
                if isVerified {
                    selfClient?.trustClient(userClient)
                } else {
                    selfClient?.ignoreClient(userClient)
                }
            case .resetSession, .removeDevice:
                break
            }
        } completionHandler: {
            sender.isOn = self.userClient.verified
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.row(at: indexPath) {

        case let .some(.info(cellViewModel)):
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: ClientTableViewCell.zm_reuseIdentifier,
                for: indexPath
            ) as? ClientTableViewCell {
                cell.selectionStyle = .default
                cell.wr_editable = false
                cell.accessibilityTraits = .none
                cell.accessibilityHint = ""
                cell.viewModel = cellViewModel
                return cell
            }

        case let .some(.fingerprint(fingerprintData)):
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: FingerprintTableViewCell.zm_reuseIdentifier,
                for: indexPath
            ) as? FingerprintTableViewCell {
                cell.selectionStyle = .none
                cell.separatorInset = .zero
                cell.fingerprint = fingerprintData
                return cell
            }

        case let .some(.verified(row)):
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: type(of: self).verifiedCellReuseIdentifier,
                for: indexPath
            ) as? SettingsToggleCell {
                cell.titleText = row.title
                cell.cellNameLabel.accessibilityIdentifier = row.labelAccessibilityIdentifier
                cell.switchView.addTarget(
                    self,
                    action: #selector(SettingsClientViewController.onVerifiedChanged(_:)),
                    for: .touchUpInside
                )
                cell.switchView.accessibilityIdentifier = row.switchAccessibilityIdentifier
                cell.accessibilityIdentifier = row.accessibilityIdentifier
                cell.switchView.isOn = row.isOn
                return cell
            }

        case let .some(.resetSession(row)):
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: type(of: self).resetCellReuseIdentifier,
                for: indexPath
            ) as? SettingsTableCell {
                cell.titleText = row.title
                cell.accessibilityIdentifier = row.accessibilityIdentifier
                return cell
            }

        case let .some(.removeDevice(row)):
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: type(of: self).deleteCellReuseIdentifier,
                for: indexPath
            ) as? SettingsTableCell {
                cell.titleText = row.title
                cell.accessibilityIdentifier = row.accessibilityIdentifier
                return cell
            }

        case nil:
            break
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch viewModel.actionForSelectingRow(at: indexPath) {
        case let .some(.resetSession(userClient)):
            userClient.resetSession()
            activityIndicator.start()

        case let .some(.removeDevice(userClient)):
            removalObserver = nil

            let completion: ((Error?) -> Void) = { error in
                if error == nil {
                    self.navigationController?.popViewController(animated: true)
                }
            }

            removalObserver = ClientRemovalObserver(
                userClientToDelete: userClient,
                delegate: self,
                userSession: userSession,
                credentials: credentials,
                completion: completion
            )

            removalObserver?.startRemoval()

        case .some(.setVerified):
            break

        case nil:
            break
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        viewModel.footerTitle(for: section)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }

    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = headerFooterViewTextColor
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        topSeparator.scrollViewDidScroll(scrollView: scrollView)
    }

    // MARK: - Copying user client info

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        viewModel.shouldShowCopyMenu(for: indexPath)
    }

    func tableView(
        _ tableView: UITableView,
        canPerformAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {

        if action == #selector(UIResponder.copy(_:)) {
            viewModel.shouldShowCopyMenu(for: indexPath)
        } else {
            false
        }
    }

    func tableView(
        _ tableView: UITableView,
        performAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) {
        if action == #selector(UIResponder.copy(_:)) {
            UIPasteboard.general.string = viewModel.copyText(for: indexPath)
        }
    }

    // MARK: - UserClientObserver

    func userClientDidChange(_ changeInfo: UserClientChangeInfo) {
        if let tableView {
            tableView.reloadData()
        }

        if changeInfo.sessionHasBeenReset {
            activityIndicator.stop()
            let alert = UIAlertController(
                title: "",
                message: L10n.Localizable.Self.Settings.DeviceDetails.ResetSession.success,
                preferredStyle: .alert
            )
            let okAction = UIAlertAction(
                title: L10n.Localizable.General.ok,
                style: .default,
                handler: { [unowned alert] _ in
                    alert.dismiss(animated: true, completion: .none)
                }
            )
            alert.addAction(okAction)
            present(alert, animated: true, completion: .none)
        }
    }
}

// MARK: - ClientRemovalObserverDelegate

extension SettingsClientViewController: ClientRemovalObserverDelegate {
    func setIsLoadingViewVisible(_ clientRemovalObserver: ClientRemovalObserver, isVisible: Bool) {
        activityIndicator.setIsActive(isVisible)
    }

    func present(_ clientRemovalObserver: ClientRemovalObserver, viewControllerToPresent: UIViewController) {
        present(viewControllerToPresent, animated: true)
    }
}

extension UserClient {
    var information: String {
        var lines = [String]()
        if let model {
            lines.append("Device: \(model)")
        }
        if let remoteIdentifier {
            lines.append("ID: \(remoteIdentifier)")
        }
        if let pushToken = PushTokenStorage.pushToken {
            lines.append("Push Token: \(pushToken.deviceTokenString)")
        }
        return lines.joined(separator: "\n")
    }
}
