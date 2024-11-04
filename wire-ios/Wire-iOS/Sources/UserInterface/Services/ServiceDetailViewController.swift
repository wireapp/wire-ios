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
import WireDesign
import WireSyncEngine

extension ConversationLike where Self: SwiftConversationLike {
    var botCanBeAdded: Bool {
        return conversationType != .oneOnOne &&
               teamType != nil &&
               allowServices
    }
}

struct Service {
    let serviceUser: ServiceUser
    var serviceUserDetails: ServiceDetails?
    var provider: ServiceProvider?
}

extension Service {
    init(serviceUser: ServiceUser) {
        self.serviceUser = serviceUser
        self.serviceUserDetails = nil
        self.provider = nil
    }
}

final class ServiceDetailViewController: UIViewController {

    typealias Completion = (AddBotResult?) -> Void

    enum ActionType {
        case addService(ZMConversation), removeService(ZMConversation), openConversation
    }

    var service: Service {
        didSet {
            self.detailView.service = service
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    let completion: Completion?
    weak var viewControllerDismisser: ViewControllerDismisser?

    private let detailView: ServiceDetailView
    private let actionButton: ZMButton
    private let actionType: ActionType
    private let userSession: UserSession

    /// init method with ServiceUser, destination conversation and customized UI.
    ///
    /// - Parameters:
    ///   - serviceUser: a ServiceUser to show
    ///   - destinationConversation: the destination conversation of the serviceUser
    ///   - actionType: Enum ActionType to choose the actiion add or remove the service user
    ///   - selfUser: self user, for inject mock user for testing
    ///   - completion: completion handler
    init(
        serviceUser: ServiceUser,
        actionType: ActionType,
        userSession: UserSession,
        completion: Completion? = nil
    ) {
        self.service = Service(serviceUser: serviceUser)
        self.completion = completion
        self.userSession = userSession

        detailView = ServiceDetailView(service: service)

        let selfUser = userSession.selfUser

        switch actionType {
        case let .addService(conversation):
            actionButton = .createAddServiceButton()
            actionButton.isHidden = !selfUser.canAddService(to: conversation)
        case let .removeService(conversation):
            actionButton = .createDestructiveServiceButton()
            actionButton.isHidden = !selfUser.canRemoveService(from: conversation)
        case .openConversation:
            actionButton = .openServiceConversationButton()
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

        if let title = self.service.serviceUser.name {
            setupNavigationBarTitle(title)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            icon: .cross,
            target: self,
            action: #selector(ServiceDetailViewController.dismissButtonTapped(_:))
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "close"
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.ServiceDetails.CloseButton.description
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

        guard let userSession = userSession as? ZMUserSession else {
            return
        }

        self.service.serviceUser.fetchProvider(in: userSession) { [weak self] provider in
            self?.detailView.service.provider = provider
        }

        self.service.serviceUser.fetchDetails(in: userSession) { [weak self] details in
            self?.detailView.service.serviceUserDetails = details
        }
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

    @objc
    func backButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissButtonTapped(_ sender: AnyObject!) {
        self.navigationController?.dismiss(animated: true) { [weak self] in
            self?.completion?(nil)
        }
    }

    func callback(
        for type: ActionType,
        sender: UIView,
        completion: Completion?
    ) -> Callback<LegacyButton> {
        { [weak self] _ in
            guard let `self`, let userSession = userSession as? ZMUserSession else {
                return
            }
            let serviceUser = self.service.serviceUser
            switch type {

            case let .addService(conversation):
                conversation.add(serviceUser: serviceUser, in: userSession) { result in

                    switch result {
                    case .success:
                        completion?(.success(conversation: conversation))
                    case .failure(let error):
                        completion?(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                    }
                }

            case let .removeService(conversation):
                self.presentRemoveDialogue(
                    for: serviceUser,
                    from: conversation,
                    sender: sender,
                    dismisser: self.viewControllerDismisser
                )

            case .openConversation:
                if let existingConversation = ZMConversation.existingConversation(in: userSession.managedObjectContext, service: serviceUser, team: userSession.selfUser.membership?.team) {
                    completion?(.success(conversation: existingConversation))
                } else {
                    serviceUser.createConversation(in: userSession, completionHandler: { result in
                        switch result {
                        case .success(let conversation):
                            completion?(.success(conversation: conversation))
                        case .failure(let error):
                            completion?(.failure(error: (error as? AddBotError) ?? AddBotError.general))
                        }
                    })
                }
            }
        }
    }
}

fileprivate extension ZMButton {

    typealias PeoplePickerServices = L10n.Localizable.Peoplepicker.Services

    static func openServiceConversationButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: PeoplePickerServices.OpenConversation.item.capitalized
        )
    }

    static func createAddServiceButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: PeoplePickerServices.AddService.button.capitalized
        )
    }

    static func createDestructiveServiceButton() -> Self {
        .init(
            style: .accentColorTextButtonStyle,
            title: L10n.Localizable.Participants.Services.RemoveIntegration.button.capitalized
        )
    }

    convenience init(style: ButtonStyle, title: String) {
        self.init(style: style, cornerRadius: 16, fontSpec: .normalSemiboldFont)
        self.setTitle(title, for: .normal)
    }
}
