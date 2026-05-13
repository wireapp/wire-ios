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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

final class ConnectRequestsViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate {

    var connectionRequests: [ConversationLike] {
        get {
            viewModel.connectionRequests
        }
        set {
            viewModel.update(connectionRequests: newValue)
        }
    }

    private var userObserverToken: Any?
    private var pendingConnectionsListObserverToken: Any?
    private let tableView: UITableView = .init(frame: .zero)
    private var lastLayoutBounds = CGRect.zero
    private let viewModel = ConnectRequestsViewModel()
    let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = tableView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ConnectRequestCell.register(in: tableView)
        tableView.delegate = self
        tableView.dataSource = self

        if !ProcessInfo.processInfo.isRunningTests {
            let pendingConnectionsList = userSession.pendingConnectionConversationsInUserSession()
            connectionRequests = pendingConnectionsList.items
            pendingConnectionsListObserverToken = userSession.addConversationListObserver(
                self,
                for: pendingConnectionsList
            )
            userObserverToken = userSession.addUserObserver(self, for: userSession.selfUser)
        }

        reload()

        tableView.backgroundColor = SemanticColors.View.backgroundDefault
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = SemanticColors.View.backgroundSeparatorCell

        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !lastLayoutBounds.size.equalTo(view.bounds.size) {
            lastLayoutBounds = view.bounds
            tableView.reloadData()

            let yPos = tableView.contentSize.height - tableView.bounds.size.height + view.safeAreaInsets.bottom
            tableView.contentOffset = CGPoint(x: 0, y: yPos)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.tableView.reloadData()
        }, completion: nil)

        super.viewWillTransition(to: size, with: coordinator)
    }

    private func setupNavigationBar() {
        setupNavigationBarTitle(L10n.Localizable.Inbox.title.capitalized)
        let button = AuthenticationNavigationBar.makeBackButton()
        button.addTarget(self, action: #selector(onBackButtonPressed), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: ConnectRequestCell.self, for: indexPath)

        configureCell(cell, for: indexPath)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        viewModel.rowHeight(forAvailableHeight: view.safeAreaLayoutGuide.layoutFrame.size.height)
    }

    // MARK: - Helpers

    @objc
    func onBackButtonPressed() {
        ZClientViewController.shared?.showConversationList()
    }

    private func configureCell(_ cell: ConnectRequestCell, for indexPath: IndexPath) {
        guard let row = viewModel.row(at: indexPath) else { return }

        cell.configure(user: row.user, userSession: userSession)
        cell.selectionStyle = .none
        cell.separatorInset = .zero
        cell.preservesSuperviewLayoutMargins = false
        cell.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)

        cell.acceptBlock = { [weak self] in
            self?.acceptConnectionRequest(from: row.user)
        }

        cell.ignoreBlock = { [weak self] in
            self?.ignoreConnectionRequest(from: row.user)
        }

    }

    private func acceptConnectionRequest(from user: UserType) {
        viewModel.accept(user: user) { [weak self] routes in
            self?.handle(routes)
        }
    }

    private func ignoreConnectionRequest(from user: UserType) {
        viewModel.ignore(user: user) { [weak self] routes in
            self?.handle(routes)
        }
    }

    private func handle(_ routes: [ConnectRequestsViewModel.Route], animated: Bool = true) {
        routes.forEach { route in
            switch route {
            case .hideRequests:
                hideRequests()
            case let .selectConversation(conversation):
                select(conversation: conversation)
            case let .showNextRequest(indexPath):
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            case let .showError(error):
                presentLocalizedErrorAlert(error)
            }
        }
    }

    private func hideRequests() {
        // TODO: [WPB-11994] test this flow manually
        ZClientViewController.shared?.hideIncomingContactRequests()
    }

    private func select(conversation: ZMConversation) {
        ZClientViewController.shared?.select(
            conversation: conversation,
            focusOnView: true,
            animated: true
        )
    }

    func reload(animated: Bool = true) {
        if !ProcessInfo.processInfo.isRunningTests {
            let pendingConnectionsList = userSession.pendingConnectionConversationsInUserSession()
            connectionRequests = pendingConnectionsList.items
        }

        tableView.reloadData()

        handle(viewModel.routesAfterReloadIfIdle(), animated: animated)
    }
}

// MARK: - ZMConversationListObserver

extension ConnectRequestsViewController: ZMConversationListObserver {
    func conversationListDidChange(_ change: ConversationListChangeInfo) {
        reload()
    }
}

// MARK: - ZMUserObserving

extension ConnectRequestsViewController: UserObserving {
    func userDidChange(_ change: UserChangeInfo) {
        tableView
            .reloadData() // may need a slightly different approach, like enumerating through table cells of type
        // FirstTimeTableViewCell and setting their bgColor property
    }
}
