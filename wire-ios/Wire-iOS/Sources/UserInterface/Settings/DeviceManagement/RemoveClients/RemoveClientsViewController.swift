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

import SwiftUI
import WireCommonComponents
import WireDesign
import WireReusableUIComponents
import WireSyncEngine

protocol RemoveClientsViewControllerDelegate: AnyObject {
    func finishedDeleting(_ clientListViewController: RemoveClientsViewController)
    func failedToDeleteClients(_ error: Error)
}

final class RemoveClientsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ClientColorVariantProtocol {
    // MARK: - Properties

    private let clientsTableView = UITableView(frame: CGRect.zero, style: .grouped)

    private var requestPasswordController: RequestPasswordController?

    weak var delegate: RemoveClientsViewControllerDelegate?
    private var viewModel: RemoveClientsViewController.ViewModel

    private lazy var activityIndicator = BlockingActivityIndicator(view: view)

    // MARK: - Life cycle

    required init(clientsList: [UserClient]) {
        self.viewModel = RemoveClientsViewController.ViewModel(
            clientsList: clientsList
        )

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibNameOrNil:nibBundleOrNil:) has not been implemented")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        [.portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createTableView()
        createConstraints()
    }

    // MARK: - Helpers

    private func createTableView() {
        clientsTableView.translatesAutoresizingMaskIntoConstraints = false
        clientsTableView.delegate = self
        clientsTableView.dataSource = self
        clientsTableView.rowHeight = UITableView.automaticDimension
        clientsTableView.estimatedRowHeight = 80
        clientsTableView.register(
            RemoveClientTableViewCell.self,
            forCellReuseIdentifier: RemoveClientTableViewCell.zm_reuseIdentifier
        )
        clientsTableView.isEditing = true
        clientsTableView.backgroundColor = SemanticColors.View.backgroundDefault
        clientsTableView.separatorStyle = .none
        view.addSubview(clientsTableView)
    }

    private func createConstraints() {
        clientsTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            clientsTableView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            clientsTableView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            clientsTableView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            clientsTableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
        ])
    }

    // MARK: - Actions

    @objc
    func backPressed(_: AnyObject!) {
        navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func removeUserClient(_ userClient: UserClient) async {
        if let password = await presentRequestPasswordController() {
            await removeUserClient(userClient, password: password)
        }
    }

    // MARK: - Helpers

    private func presentRequestPasswordController() async -> String? {
        await withCheckedContinuation { continuation in
            requestPasswordController = RequestPasswordController(
                context: .removeDevice,
                callback: { password in
                    continuation.resume(returning: password)
                }
            )
            guard let alertController = requestPasswordController?.alertController else {
                continuation.resume(returning: nil)
                return
            }

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func removeUserClient(_ userClient: UserClient, password: String) async {
        activityIndicator.start()
        do {
            try await viewModel.removeUserClient(userClient, password: password)
            delegate?.finishedDeleting(self)
        } catch {
            delegate?.failedToDeleteClients(error)
        }
        activityIndicator.stop()
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.clients.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        L10n.Localizable.Registration.Devices.activeListHeader
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.Localizable.Registration.Devices.activeListSubtitle
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: RemoveClientTableViewCell.zm_reuseIdentifier,
            for: indexPath
        ) as? RemoveClientTableViewCell {
            cell.selectionStyle = .none
            cell.viewModel = .init(userClient: viewModel.clients[indexPath.row], shouldSetType: false)

            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        let userClient = viewModel.clients[indexPath.row]
        Task {
            await removeUserClient(userClient)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell
        .EditingStyle {
        viewModel.clients[indexPath.row].type == .legalHold ? .none : .delete
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.preservesSuperviewLayoutMargins = false
    }
}

extension RemoveUserClientError: LocalizedError {
    public var errorDescription: String? {
        L10n.Localizable.General.failure
    }
}
