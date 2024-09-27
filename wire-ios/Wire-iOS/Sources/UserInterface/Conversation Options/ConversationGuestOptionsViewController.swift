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

// MARK: - ConversationGuestLink

enum ConversationGuestLink {
    static let didCreateSecureGuestLinkNotification = Notification.Name(
        "Conversation.didCreateSecureGuestLink"
    )
}

// MARK: - ConversationGuestOptionsViewController

final class ConversationGuestOptionsViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    ConversationGuestOptionsViewModelDelegate {
    private let tableView = UITableView()
    private var viewModel: ConversationGuestOptionsViewModel
    private var guestLinkObserver: NSObjectProtocol?

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
            viewModel: .init(
                configuration: configuration,
                conversation: conversation,
                createSecureGuestLinkUseCase: userSession.makeConversationSecureGuestLinkUseCase()
            )
        )
    }

    init(viewModel: ConversationGuestOptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupViews()
        createConstraints()
        viewModel.delegate = self
    }

    deinit {
        if let observer = guestLinkObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guestLinkObserver = NotificationCenter.default.addObserver(
            forName: ConversationGuestLink.didCreateSecureGuestLinkNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleGuestLinkNotification(notification)
        }

        setupNavigationBar()
    }

    private func handleGuestLinkNotification(_ notification: Notification) {
        if let link = notification.userInfo?["link"] as? String {
            viewModel.securedLink = link
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        view.addSubview(tableView)
        view.backgroundColor = SemanticColors.View.backgroundDefault

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

    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = SemanticColors.Label.textDefault

        navigationController?.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault

        setupNavigationBarTitle(L10n.Localizable.GroupDetails.GuestOptionsCell.title.capitalized)

        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Accessibility.ConversationDetails.CloseButton.description)
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

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        didUpdateState state: ConversationGuestOptionsViewModel.State
    ) {
        activityIndicator.setIsActive(state.isLoading)
        tableView.reloadData()
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        didReceiveError error: Error
    ) {
        // We shouldn't display an error message if the guestLinks feature flag is disabled. There's a UI element that
        // explains why the user cannot use/create links to join the conversation.

        if let error = error as? WirelessLinkError,
           error == .guestLinksDisabled {
            return
        } else {
            present(UIAlertController.checkYourConnection(), animated: false)
        }
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        confirmRemovingGuests completion: @escaping (Bool) -> Void
    ) -> UIAlertController? {
        let alertController = UIAlertController.confirmRemovingGuests(completion)
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView.superview!
            popoverPresentationController.sourceRect = sourceView.frame
        }
        present(alertController, animated: true)
        return alertController
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        presentGuestLinkTypeSelection completion: @escaping (GuestLinkType) -> Void
    ) {
        let alertController = UIAlertController.guestLinkTypeController { guestLinkType in
            completion(guestLinkType)
        }
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView.superview!
            popoverPresentationController.sourceRect = sourceView.frame
        }
        present(alertController, animated: true)
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        sourceView: UIView,
        confirmRevokingLink completion: @escaping (Bool) -> Void
    ) {
        let alertController = UIAlertController.confirmRevokingLink(completion)
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView.superview!
            popoverPresentationController.sourceRect = sourceView.frame
        }
        present(alertController, animated: true)
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        wantsToShareMessage message: String,
        sourceView: UIView
    ) {
        let activityController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        if let popoverPresentationController = activityController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView.superview!
            popoverPresentationController.sourceRect = sourceView.frame
        }

        present(activityController, animated: true)
    }

    func conversationGuestOptionsViewModel(
        _ viewModel: ConversationGuestOptionsViewModel,
        presentCreateSecureGuestLink viewController: UIViewController,
        animated: Bool
    ) {
        present(viewController, animated: animated)
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: row.cellType.reuseIdentifier,
            for: indexPath
        ) as! CellConfigurationConfigurable
        cell.configure(with: row)
        return cell as! UITableViewCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)!
        viewModel.state.rows[indexPath.row].action?(cell)
    }
}
