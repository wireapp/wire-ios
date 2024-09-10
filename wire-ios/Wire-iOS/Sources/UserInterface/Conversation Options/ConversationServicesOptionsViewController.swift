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
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

final class ConversationServicesOptionsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ConversationServicesOptionsViewModelDelegate {
    private let tableView = UITableView()
    private var viewModel: ConversationServicesOptionsViewModel

    private lazy var activityIndicator = BlockingActivityIndicator(view: navigationController?.view ?? view)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    convenience init(conversation: ZMConversation, userSession: ZMUserSession) {
        let configuration = ZMConversation.OptionsConfigurationContainer(
            conversation: conversation,
            userSession: userSession
        )
        self.init(
            viewModel: .init(configuration: configuration)
        )
    }

    init(viewModel: ConversationServicesOptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
        viewModel.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupNavigationBarTitle(L10n.Localizable.GroupDetails.ServicesOptionsCell.title.capitalized)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Accessibility.ServiceConversationSettings.CloseButton.description)
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
        tableView.contentInsetAdjustmentBehavior = .never
    }

    private func createConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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

    func conversationServicesOptionsViewModel(
        _ viewModel: ConversationServicesOptionsViewModel,
        fallbackActivityPopoverConfiguration: PopoverPresentationControllerConfiguration,
        confirmRemovingServices completion: @escaping (Bool) -> Void
    ) -> UIAlertController? {
        let alertController = UIAlertController.confirmRemovingServices(completion)
        alertController.configurePopoverPresentationController(using: fallbackActivityPopoverConfiguration)
        present(alertController, animated: true)

        return alertController
    }

    // MARK: – UITableViewDelegate & UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.rows.count
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        viewModel.state.rows[indexPath.row].action != nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.state.rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath) as! CellConfigurationConfigurable
        cell.configure(with: row)
        return cell as! UITableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)!
        viewModel.state.rows[indexPath.row].action?(cell)
    }
}
