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
import WireLogging
import WireNetwork
import WireSyncEngine

extension ConversationLike where Self: GroupDetailsConversationType {
    var botCanBeAdded: Bool {
        conversationType != .oneOnOne && teamType != nil
    }
}

struct Service {

    let user: any WireDataModel.UserType
    let isLegacyBot: Bool
    var serviceUserDetails: ServiceDetails?
    var provider: ServiceProvider?

    init(user: any WireDataModel.UserType) {
        self.user = user
        self.isLegacyBot = user.isBot
    }

}

private protocol ServiceDetailActionHandling {

    func perform(
        _ route: ServiceDetailViewModel.ActionRoute,
        service: Service,
        sender: UIView,
        presentingViewController: UIViewController,
        completion: @escaping (AddBotResult) -> Void
    )

}

final class ServiceDetailViewController: UIViewController {

    enum ActionType {
        case addApp(ZMConversation)
        case addBot(ZMConversation)
        case removeParticipant(ZMConversation)
        case openConversation
    }

    var service: Service {
        didSet {
            detailView.service = service
            detailView.viewState = viewModel.viewState
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    let completion: (AddBotResult) -> Void

    private let viewModel: ServiceDetailViewModel
    private let detailView: ServiceDetailView
    private let actionButton: ZMButton
    private let actionType: ActionType
    private let userSession: UserSession
    private let detailsFetcher: any ServiceDetailFetchHandling
    private let actionHandler: any ServiceDetailActionHandling

    init(
        user: any WireDataModel.UserType,
        actionType: ActionType,
        userSession: UserSession,
        usersAPI: (any UsersAPI)?,
        completion: @escaping (AddBotResult) -> Void
    ) {
        let viewModel = ServiceDetailViewModel(
            user: user,
            actionType: actionType,
            selfUser: userSession.selfUser
        )
        let viewState = viewModel.viewState

        self.viewModel = viewModel
        self.service = viewModel.service
        self.completion = completion
        self.userSession = userSession
        self.detailsFetcher = LegacyServiceDetailFetchHandler(
            userSession: userSession,
            usersAPI: usersAPI
        )
        self.actionHandler = DefaultServiceDetailActionHandler(userSession: userSession)

        self.detailView = ServiceDetailView(
            service: viewModel.service,
            viewState: viewState,
            userSession: userSession
        )

        self.actionButton = .createButton(for: viewState.actionButton)

        self.actionType = actionType

        super.init(nibName: nil, bundle: nil)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = viewModel.viewState.navigationTitle {
            setupNavigationBarTitle(title)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            icon: .cross,
            target: self,
            action: #selector(ServiceDetailViewController.dismissButtonTapped(_:))
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close"
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.ServiceDetails.CloseButton
            .description
    }

    private func setupViews() {
        actionButton.addCallback(
            for: .primaryActionTriggered,
            callback: callback(
                sender: actionButton,
                completion: completion
            )
        )

        view.backgroundColor = SemanticColors.View.backgroundDefault

        [detailView, actionButton].forEach(view.addSubview)

        createConstraints()

        fetchDetails()
    }

    private func createConstraints() {
        [detailView, actionButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            detailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            detailView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            actionButton.topAnchor.constraint(equalTo: detailView.bottomAnchor, constant: 16),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func fetchDetails() {
        detailsFetcher.fetchDetails(using: viewModel) { [weak self] service in
            self?.updateService(service)
        }
    }

    private func updateService(_ service: Service) {
        self.service = service
    }

    @objc
    func backButtonTapped(_ sender: AnyObject!) {
        navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissButtonTapped(_ sender: AnyObject!) {
        navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion(.cancelled)
        }
    }

    func callback(
        sender: UIView,
        completion: @escaping (AddBotResult) -> Void
    ) -> Callback<LegacyButton> {
        { [weak self] _ in
            guard let self else { return }

            actionHandler.perform(
                viewModel.actionRoute,
                service: service,
                sender: sender,
                presentingViewController: self,
                completion: completion
            )
        }
    }

}

private final class DefaultServiceDetailActionHandler: ServiceDetailActionHandling {

    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func perform(
        _ route: ServiceDetailViewModel.ActionRoute,
        service: Service,
        sender: UIView,
        presentingViewController: UIViewController,
        completion: @escaping (AddBotResult) -> Void
    ) {
        guard let userSession = userSession as? ZMUserSession else { return }

        switch route {
        case let .addApp(conversation):
            addApp(
                to: conversation,
                service: service,
                userSession: userSession,
                completion: completion
            )

        case let .addBot(conversation):
            addBot(
                to: conversation,
                service: service,
                userSession: userSession,
                completion: completion
            )

        case let .removeParticipant(conversation):
            presentingViewController.presentRemoveDialogue(
                for: service.user,
                from: conversation,
                sender: sender
            )

        case .openConversationWithBot:
            openConversationWithBot(
                service: service,
                userSession: userSession,
                completion: completion
            )

        case .openConversationWithApp:
            openConversationWithApp(
                service: service,
                userSession: userSession,
                completion: completion
            )
        }
    }

    private func addApp(
        to conversation: ZMConversation,
        service: Service,
        userSession: ZMUserSession,
        completion: @escaping (AddBotResult) -> Void
    ) {
        guard let user = service.user as? ZMUser else {
            return completion(.failure(error: .general))
        }

        Task { @MainActor [weak self] in
            do {
                guard self != nil else { return }

                let syncContext = userSession.syncContext
                let conversationParticipantsService = ConversationParticipantsService(
                    context: syncContext,
                    localDomain: userSession.resolvedBackendMetadata.domain
                )
                let user = try await syncContext.perform { [objectID = user.objectID] in
                    try ZMUser.existingObject(for: objectID, in: syncContext)
                }
                let conversation_ = try await syncContext.perform { [objectID = conversation.objectID] in
                    return try ZMConversation.existingObject(for: objectID, in: syncContext)
                }

                try await conversationParticipantsService.addParticipants([user], to: conversation_)
                try await syncContext.perform {
                    try syncContext.save()
                }
                completion(.success(conversation: conversation))
            } catch {
                completion(.failure(error: (error as? AddBotError) ?? AddBotError.general))
            }
        }
    }

    private func addBot(
        to conversation: ZMConversation,
        service: Service,
        userSession: ZMUserSession,
        completion: @escaping (AddBotResult) -> Void
    ) {
        conversation.add(bot: service.user, in: userSession) { result in
            switch result {
            case .success:
                completion(.success(conversation: conversation))
            case let .failure(error):
                completion(.failure(error: (error as? AddBotError) ?? AddBotError.general))
            }
        }
    }

    private func openConversationWithApp(
        service: Service,
        userSession: ZMUserSession,
        completion: @escaping (AddBotResult) -> Void
    ) {
        if let existingConversation = ZMConversation.existingConversation(
            in: userSession.managedObjectContext,
            service: service.user,
            team: userSession.selfUser.membership?.team
        ) {
            completion(.success(conversation: existingConversation))
        } else {
            service.user.createConversation(in: userSession) { result in
                switch result {
                case let .success(conversation):
                    completion(.success(conversation: conversation))
                case let .failure(error):
                    completion(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                }
            }
        }
    }

    private func openConversationWithBot(
        service: Service,
        userSession: ZMUserSession,
        completion: @escaping (AddBotResult) -> Void
    ) {
        let user = service.user
        Task { @MainActor [weak self] in
            guard self != nil else { return }

            guard let userID = user.qualifiedID(
                localDomain: userSession.resolvedBackendMetadata.domain
            ) else {
                return completion(.failure(error: AddBotError.general))
            }

            let conversation = user.oneToOneConversation
            do {
                let isReady = try await userSession.checkOneOnOneConversationIsReady.invoke(userID: userID)
                if isReady {
                    guard let conversation else {
                        return completion(.failure(error: AddBotError.general))
                    }
                    completion(.success(conversation: conversation))
                } else {
                    userSession.createTeamOneOnOne(with: user) { result in
                        switch result {
                        case let .success(conversation):
                            completion(.success(conversation: conversation))
                        case let .failure(error):
                            WireLogger.conversation
                                .warn("failed to create team one on one from search result: \(error)")
                            completion(.failure(error: AddBotError.general))
                        }
                    }
                }
            } catch {
                WireLogger.conversation
                    .warn("failed to check if one on one conversation is ready: \(error)")
                completion(.failure(error: AddBotError.general))
            }
        }
    }

}

private extension ZMButton {

    static func createButton(for state: ServiceDetailViewModel.ActionButtonState) -> Self {
        let button = Self(style: .accentColorTextButtonStyle, title: state.title)
        button.isHidden = state.isHidden
        return button
    }

    convenience init(style: ButtonStyle, title: String) {
        self.init(style: style, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        setTitle(title, for: .normal)
    }
}
