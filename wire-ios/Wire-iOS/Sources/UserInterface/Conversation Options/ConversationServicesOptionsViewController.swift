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
import WireDesign
import WireReusableUIComponents
import WireSyncEngine
import WireUtilities

final class ConversationServicesOptionsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ConversationServicesOptionsViewModelDelegate {

    private let tableView = UITableView()
    private var viewModel: ConversationServicesOptionsViewModel
    private let setAllowApps: ((Bool, @escaping (Result<Void, Error>) -> Void) -> Void)?
    private var loadingItem: CancelableItem?

    private lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    convenience init(
        conversation: ZMConversation,
        userSession: ZMUserSession,
        areLegacyBotsAvailable: Bool,
        isAppsFeatureEnabled: Bool
    ) {
        let configuration = ZMConversation.OptionsConfigurationContainer(
            conversation: conversation,
            userSession: userSession,
            areLegacyBotsAvailable: areLegacyBotsAvailable,
            isAppsFeatureEnabled: isAppsFeatureEnabled
        )
        self.init(
            viewModel: .init(configuration: configuration),
            setAllowApps: configuration.setAllowApps
        )
    }

    init(
        viewModel: ConversationServicesOptionsViewModel,
        setAllowApps: ((Bool, @escaping (Result<Void, Error>) -> Void) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.setAllowApps = setAllowApps
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavigationBarTitle(viewModel.state.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: viewModel.state.closeButtonAccessibilityLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        view.addSubview(tableView)
        CellConfiguration.prepare(tableView)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 32, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: – ConversationOptionsViewModelDelegate

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        didUpdateState state: ConversationServicesOptionsViewModel.State
    ) {
        activityIndicator.setIsActive(state.isLoading)
        tableView.reloadData()
    }

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        didReceiveError error: Error
    ) {
        present(UIAlertController.checkYourConnection(), animated: false)
    }

    // MARK: – UITableViewDelegate & UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.rows.count
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.state.rows[indexPath.row]
        let configuration = cellConfiguration(for: row)
        let cell = tableView.dequeueReusableCell(
            withIdentifier: configuration.cellType.reuseIdentifier,
            for: indexPath
        ) as! CellConfigurationConfigurable
        cell.configure(with: configuration)
        return cell as! UITableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func cellConfiguration(for row: ConversationServicesOptionsViewModel.Row) -> CellConfiguration {
        switch row {
        case let .appsDisabledHint(title, body):
            return .titleAndBody(title: title, body: body)

        case let .allowAppsToggle(toggle):
            return .iconToggle(
                title: toggle.title,
                subtitle: toggle.subtitle,
                identifier: toggle.accessibilityIdentifier,
                titleIdentifier: toggle.titleAccessibilityIdentifier,
                icon: nil,
                color: nil,
                isEnabled: toggle.isEnabled,
                get: { toggle.isOn },
                set: { [weak self] allowApps, sender in
                    guard let self else { return }
                    handle(viewModel.actionForAllowAppsToggle(allowApps), sender: sender)
                }
            )
        }
    }

    private func handle(
        _ action: ConversationServicesOptionsViewModel.Action,
        sender: UIView
    ) {
        switch action {
        case .none:
            return

        case let .confirmRemovingServices(allowApps):
            confirmRemovingServices(allowApps: allowApps, sender: sender)

        case let .setAllowApps(allowApps):
            saveAllowApps(allowApps)
        }
    }

    private func confirmRemovingServices(
        allowApps: Bool,
        sender: UIView
    ) {
        let alertController = UIAlertController.confirmRemovingServices { [weak self] confirmed in
            guard let self else { return }

            handle(
                viewModel.actionForRemovingServicesConfirmation(
                    confirmed: confirmed,
                    allowApps: allowApps
                ),
                sender: sender
            )
        }
        alertController.configurePopoverPresentationController(
            using: .sourceView(
                sourceView: sender.superview ?? sender,
                sourceRect: sender.frame.insetBy(dx: -4, dy: -4)
            )
        )
        present(alertController, animated: true)
    }

    private func saveAllowApps(_ allowApps: Bool) {
        guard let setAllowApps else {
            viewModel.applySetAllowAppsResult(.success(()))
            return
        }

        loadingItem = CancelableItem(delay: 0.4) { [weak self] in
            self?.viewModel.updateIsLoading(true)
        }

        setAllowApps(allowApps) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                loadingItem?.cancel()
                loadingItem = nil
                viewModel.applySetAllowAppsResult(result)
            }
        }
    }
}
