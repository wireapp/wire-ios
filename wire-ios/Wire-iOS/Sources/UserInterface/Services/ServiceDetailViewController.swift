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

final class ServiceDetailViewController: UIViewController {

    enum ActionType {
        case addApp(ZMConversation)
        case removeApp(ZMConversation)
        case addBot(ZMConversation)
        case removeBot(ZMConversation)
        case openConversation
    }

    var service: Service {
        didSet {
            detailView.service = service
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    let completion: (AddBotResult) -> Void

    private let detailView: ServiceDetailView
    private let actionButton: ZMButton
    private let actionType: ActionType
    private let userSession: UserSession
    private let teamsAPI: any TeamsAPI

    /// init method with ServiceUser, destination conversation and customized UI.
    ///
    /// - Parameters:
    ///   - user: an app or a bot user to show
    ///   - destinationConversation: the destination conversation of the serviceUser
    ///   - actionType: Enum ActionType to choose the action add or remove the service user
    ///   - selfUser: self user, for inject mock user for testing
    ///   - completion: completion handler
    init(
        user: any WireDataModel.UserType,
        actionType: ActionType,
        userSession: UserSession,
        teamsAPI: any TeamsAPI,
        completion: @escaping (AddBotResult) -> Void
    ) {
        self.service = Service(user: user)
        self.completion = completion
        self.userSession = userSession
        self.teamsAPI = teamsAPI

        self.detailView = ServiceDetailView(service: service)

        let selfUser = userSession.selfUser

        switch actionType {
        case let .addApp(conversation), let .addBot(conversation):
            self.actionButton = .createAddAppButton()
            actionButton.isHidden = !selfUser.canAddService(to: conversation)
        case let .removeApp(conversation), let .removeBot(conversation):
            self.actionButton = .createDestructiveAppButton()
            actionButton.isHidden = !selfUser.canRemoveService(from: conversation)
        case .openConversation:
            self.actionButton = .openAppConversationButton()
            actionButton.isHidden = !selfUser.canCreateService
        }

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

        if let title = service.user.name {
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
                for: actionType,
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
        guard let userSession = userSession as? ZMUserSession else { return }

        if
            !service.isLegacyBot,
            let teamID = service.user.membership?.team?.remoteIdentifier,
            let appID = service.user.remoteIdentifier {

            Task {
                do {
                    let appDetails = try await teamsAPI.getApp(
                        for: teamID,
                        with: appID
                    )
                    detailView.service.serviceUserDetails = ServiceDetails(
                        serviceIdentifier: "",
                        providerIdentifier: "",
                        name: appDetails.name,
                        serviceDescription: appDetails.description,
                        assets: [], // TODO: convert assets
                        tags: []
                    )
                    detailView.service.provider = ServiceProvider(
                        identifier: "",
                        name: "TODO", // TODO: appDetails.author?
                        email: "",
                        url: "",
                        providerDescription: ""
                    )
                } catch {
                    WireLogger.ui.error("failed to get app details", attributes: .safePublic)
                }
            }

        } else if let bot = service.user as? any Bot {

            bot.fetchProvider(in: userSession) { [weak self] provider in
                self?.detailView.service.provider = provider
            }

            bot.fetchDetails(in: userSession) { [weak self] details in
                self?.detailView.service.serviceUserDetails = details
            }

        }
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
        for type: ActionType,
        sender: UIView,
        completion: @escaping (AddBotResult) -> Void
    ) -> Callback<LegacyButton> {
        { [weak self] _ in
            guard let self, let userSession = userSession as? ZMUserSession, let bot = service.user as? any Bot else {
                return
            }

            switch type {

            case let .addApp(conversation):
                fatalError()

            case let .removeApp(conversation):
                fatalError()

            case let .addBot(conversation):
                conversation.add(bot: bot, in: userSession) { result in
                    switch result {
                    case .success:
                        completion(.success(conversation: conversation))
                    case let .failure(error):
                        completion(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                    }
                }

            case let .removeBot(conversation):
                presentRemoveDialogue(
                    for: bot,
                    from: conversation,
                    sender: sender
                )

            case .openConversation: // TODO: apps?
                if let existingConversation = ZMConversation.existingConversation(
                    in: userSession.managedObjectContext,
                    bot: bot,
                    team: userSession.selfUser.membership?.team
                ) {
                    completion(.success(conversation: existingConversation))
                } else { // TODO: apps?
                    bot.createConversation(in: userSession, completionHandler: { result in
                        switch result {
                        case let .success(conversation):
                            completion(.success(conversation: conversation))
                        case let .failure(error):
                            completion(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                        }
                    })
                }
            }
        }
    }
}

private extension ZMButton {

    typealias PeoplePickerApps = L10n.Localizable.Peoplepicker.Apps

    static func openAppConversationButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: PeoplePickerApps.OpenConversation.item.capitalized
        )
    }

    static func createAddAppButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: PeoplePickerApps.AddApp.button.capitalized
        )
    }

    static func createDestructiveAppButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: L10n.Localizable.Participants.Apps.RemoveIntegration.button.capitalized
        )
    }

    convenience init(style: ButtonStyle, title: String) {
        self.init(style: style, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        setTitle(title, for: .normal)
    }
}
