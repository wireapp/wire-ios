//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import UIKit
import WireDomain
import WireLogging
import WireMessagingDomain
import WireMessagingUI
import WireNetwork
import WireReusableUIComponents
import WireSyncEngine

final class WireConversationChannelCreationFormViewController: UIViewController {

    private let userSession: UserSession
    private var values: ConversationCreationValues

    private lazy var viewModel = ConversationChannelCreationFormViewModel(
        channelName: "",
        isUserPremium: userSession.isEnterpriseUser,
        isWireCellsEnabled: userSession.isWireCellsEnabled,
        teamsURL: URL.manageTeam(source: .settings),
        onFormValidityUpdate: { formIsValid in
            Task { @MainActor [weak self] in
                self?.onFormValidityUpdate(formIsValid: formIsValid)
            }
        }
    )

    weak var delegate: ConversationCreationControllerDelegate?

    private lazy var hostingController: UIHostingController<ConversationChannelCreationForm> = {
        let rootView = ConversationChannelCreationForm(
            viewModel: viewModel
        )
        return UIHostingController(rootView: rootView)
    }()

    @MainActor var channelCreationSettings: ConversationChannelCreationSettings? {
        viewModel.getChannelCreationSettings()
    }

    init(
        userSession: UserSession
    ) {
        self.userSession = userSession
        self.values = ConversationCreationValues(
            isChannel: true,
            encryptionProtocol: userSession.defaultProtocol,
            selfUser: userSession.selfUser
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = navigationBarTitle {
            setupNavigationBarTitle(title)
        }

        setupNavigationBarButtonItems()
    }

    private func setupNavigationBarButtonItems() {
        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
                self?.presentingViewController?.dismiss(animated: true)
            }, accessibilityLabel: L10n.Localizable.General.close)
        }

        let nextButton = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: L10n.Localizable.Conversation.Create.Channel.next,
            action: UIAction { @MainActor [weak self] _ in
                guard let self else { return }
                attemptToProceedToParticipants()
            }
        )
        nextButton.accessibilityIdentifier = "button.newchannel.next"
        navigationItem.rightBarButtonItem = nextButton
        nextButton.isEnabled = viewModel.isFormValid
    }

    private var navigationBarTitle: String? {
        L10n.Localizable.Conversation.Create.Channel.title
    }

    private func onFormValidityUpdate(formIsValid: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = formIsValid
    }

    @MainActor
    func attemptToProceedToParticipants() {
        guard let channelCreationSettings else {
            return
        }

        guard !channelCreationSettings.channelName.isEmpty else {
            return
        }

        values.name = channelCreationSettings.channelName
        values.allowGuests = channelCreationSettings.guestsAllowed
        values.allowApps = channelCreationSettings.appsAllowed
        values.enableReceipts = channelCreationSettings.readReceiptsEnabled
        values.channelHistoryDepth = channelCreationSettings.historyDepth
        values.enableFileManagement = channelCreationSettings.fileManagementEnabled

        let participantsController = AddParticipantsViewController(
            context: .create(values),
            userSession: userSession
        )

        participantsController.conversationCreationDelegate = self
        navigationController?.pushViewController(participantsController, animated: true)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension WireConversationChannelCreationFormViewController: AddParticipantsConversationCreationDelegate {

    func addParticipantsViewController(
        _ addParticipantsViewController: AddParticipantsViewController,
        didPerform action: AddParticipantsViewController.CreateAction
    ) {
        switch action {
        case let .updatedUsers(users):
            values.participants = users

        case .create:
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: avoid casting to `ZMUserSession` (expand `UserSession` API)
            guard let userSession = userSession as? ZMUserSession else { return }

            addParticipantsViewController.setLoadingView(isVisible: true)

            let users = values.participants
                .union([userSession.selfUser])
                .materialize(in: userSession.viewContext)

            // Switching to sync context
            let syncedUsers = userSession.syncContext.performAndWait {
                let objectIDs = users.map(\.objectID)

                return objectIDs.compactMap {
                    try? userSession.syncContext.existingObject(with: $0) as? ZMUser
                }
            }

            let team = userSession.syncContext.performAndWait {
                let selfUser = ZMUser.selfUser(in: userSession.syncContext)
                return selfUser.teamIdentifier
            }

            Task { @MainActor in
                await createChannel(
                    teamID: team!, // safe force unwrapped, we already checked team is not null
                    session: userSession,
                    users: syncedUsers
                )

                addParticipantsViewController.setLoadingView(isVisible: false)
            }
        }
    }

    private func createChannel(
        teamID: UUID,
        session: ZMUserSession,
        users: [ZMUser]
    ) async {
        guard let channelUseCase = session.createChannelUseCase else {
            return
        }

        let accessMode: [WireNetwork.ConversationAccessMode] = values.allowGuests ? [.invite, .code] : []
        let accessRoles = ConversationAccessRoleV2.from(
            allowGuests: values.allowGuests,
            allowApps: values.shouldIncludeServices ? values.allowApps : false
        ).compactMap {
            $0.toNetworkModel()
        }

        let channelHistoryDepth = values.channelHistoryDepth

        do {
            let conversation = try await channelUseCase.invoke(
                teamID: teamID,
                name: values.name,
                historyDepth: channelHistoryDepth,
                cells: userSession.isWireCellsEnabled ? values.enableFileManagement : nil,
                users: Set(users),
                accessMode: Set(accessMode),
                accessRoles: Set(accessRoles),
                enableReceipts: values.enableReceipts
            )

            // Switching back to UI context
            let syncedConversation = try session.viewContext.performAndWait {
                try session.viewContext.existingObject(with: conversation.objectID) as? ZMConversation
            }

            guard let syncedConversation else { return }

            delegate?.conversationCreationController(
                self,
                didCreateConversation: syncedConversation
            )

        } catch let error as CreateChannelUseCase.Failure {

            switch error {
            case .missingLegalholdConsent:
                showMissingLegalholdConsentAlert()

            case let .nonFederatingDomains(domains):
                showNonFederatingDomainsAlert(domains: Set(domains))

            default:
                WireLogger.conversation.error(
                    "failed to create conversation: \(String(describing: error))"
                )
                showGenericErrorAlert()
            }
        } catch {
            WireLogger.conversation.error(
                "failed to create conversation: \(String(describing: error))"
            )
            showGenericErrorAlert()
        }
    }
}

private extension WireConversationChannelCreationFormViewController {

    private func showGenericErrorAlert() {
        typealias ConnectionError = L10n.Localizable.Error.Connection

        let alert = UIAlertController(
            title: ConnectionError.title,
            message: ConnectionError.genericError,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(
            alert,
            animated: true
        )
    }

    private func showMissingLegalholdConsentAlert() {
        typealias ConversationError = L10n.Localizable.Error.Conversation

        let alert = UIAlertController(
            title: ConversationError.title,
            message: ConversationError.missingLegalholdConsent,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(
            alert,
            animated: true
        )
    }

    private func showNonFederatingDomainsAlert(domains: Set<String>) {
        typealias Strings = L10n.Localizable.Conversation.Create.NonFederatingDomainsError

        let alert = UIAlertController(
            title: Strings.title,
            message: Strings.message(ListFormatter.localizedString(byJoining: domains.sorted())),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: Strings.abort,
            style: .destructive,
            handler: abort
        ))

        alert.addAction(UIAlertAction(
            title: Strings.editParticipantList,
            style: .default
        ))

        alert.addAction(.link(
            title: Strings.learnMore,
            url: WireURLs.shared.federationInfo,
            presenter: self
        ))

        present(
            alert,
            animated: true
        )
    }

    private func abort(_ action: UIAlertAction) {
        dismiss(animated: true)
    }
}
