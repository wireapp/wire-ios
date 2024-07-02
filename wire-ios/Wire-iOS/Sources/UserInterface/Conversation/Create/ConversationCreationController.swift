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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

protocol ConversationCreationControllerDelegate: AnyObject {

    func conversationCreationController(
        _ controller: ConversationCreationController,
        didCreateConversation conversation: ZMConversation
    )

}

final class ConversationCreationController: UIViewController {

    // MARK: - Properties

    typealias CreateGroupName = L10n.Localizable.Conversation.Create.GroupName

    private let userSession: UserSession
    static let mainViewHeight: CGFloat = 56

    private let collectionViewController = SectionCollectionViewController()

    private var preSelectedParticipants: UserSet?
    private var values: ConversationCreationValues

    weak var delegate: ConversationCreationControllerDelegate?

    // MARK: - Sections

    private lazy var nameSection = ConversationCreateNameSectionController(selfUser: userSession.selfUser, delegate: self)
    private lazy var errorSection = ConversationCreateErrorSectionController()

    private lazy var optionsSections: [ConversationCreateSectionController] = {
        let sections = [
            guestsSection,
            servicesSection,
            receiptsSection,
            shouldIncludeEncryptionProtocolSection ? encryptionProtocolSection : nil
        ].compactMap { $0 }

        if let firstSection = sections.first {
            firstSection.headerTitle = L10n.Localizable.Conversation.Create.Options.title
        }

        return sections
    }()

    private var shouldIncludeEncryptionProtocolSection: Bool {
        if DeveloperFlag.showCreateMLSGroupToggle.isOn {
            return true
        }

        if AutomationHelper.sharedHelper.allowMLSGroupCreation == true {
            return true
        }

        return userSession.selfUser.canCreateMLSGroups
    }

    private lazy var guestsSection: ConversationCreateGuestsSectionController = {
        let section = ConversationCreateGuestsSectionController(values: values)

        section.toggleAction = { [unowned self] allowGuests in
            self.values.allowGuests = allowGuests
            self.updateOptions()
        }

        return section
    }()

    private lazy var servicesSection: ConversationCreateServicesSectionController = {
        let section = ConversationCreateServicesSectionController(values: values)

        section.toggleAction = { [unowned self] allowServices in
            self.values.allowServices = allowServices
            self.updateOptions()
        }
        return section
    }()

    private lazy var receiptsSection: ConversationCreateReceiptsSectionController = {
        let section = ConversationCreateReceiptsSectionController(values: values)

        section.toggleAction = { [unowned self] enableReceipts in
            self.values.enableReceipts = enableReceipts
            self.updateOptions()
        }

        return section
    }()

    private lazy var encryptionProtocolSection: ConversationEncryptionProtocolSectionController = {
        let section = ConversationEncryptionProtocolSectionController(values: values)

        section.tapAction = {
            self.presentEncryptionProtocolPicker { [weak self] encryptionProtocol in
                self?.values.encryptionProtocol = encryptionProtocol
                self?.updateOptions()
            }
        }

        return section
    }()

    // MARK: - Life cycle

    init(
        preSelectedParticipants: UserSet?,
        userSession: UserSession
    ) {
        self.preSelectedParticipants = preSelectedParticipants
        self.userSession = userSession

        let mlsFeature = userSession.makeGetMLSFeatureUseCase().invoke()
        self.values = ConversationCreationValues(
            encryptionProtocol: mlsFeature.config.defaultProtocol,
            selfUser: userSession.selfUser
        )

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameSection.becomeFirstResponder()
    }

    // MARK: - Methods

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupViews() {
        // swiftlint:disable todo_requires_jira_link
        // TODO: if keyboard is open, it should scroll.
        // swiftlint:enable todo_requires_jira_link
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        ])

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = [nameSection, errorSection]

        if userSession.selfUser.isTeamMember {
            collectionViewController.sections.append(contentsOf: optionsSections)
        }

    }

    private func setupNavigationBar() {
        navigationItem.setupNavigationBarTitle(title: CreateGroupName.title.capitalized)

        navigationController?.navigationBar.barTintColor = SemanticColors.View.backgroundDefault
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = UIColor.accent()
        navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes()

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = navigationController?.closeItem()
        }

        let nextButtonItem: UIBarButtonItem = .createNavigationRightBarButtonItem(
            title: L10n.Localizable.General.next.capitalized,
            systemImage: false,
            target: self,
            action: #selector(tryToProceed)
        )
        nextButtonItem.accessibilityIdentifier = "button.newgroup.next"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = nextButtonItem
    }

    func proceedWith(value: WireTextField.Value) {
        switch value {
        case let .error(error):
            errorSection.displayError(error)

        case let .valid(name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            nameSection.resignFirstResponder()
            values.name = trimmed

            if let parts = preSelectedParticipants {
                values.participants = parts
            }

            let participantsController = AddParticipantsViewController(
                context: .create(values),
                userSession: userSession
            )

            participantsController.conversationCreationDelegate = self
            navigationController?.pushViewController(participantsController, animated: true)
        }
    }

    @objc
    private func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }

    private func updateOptions() {
        self.guestsSection.configure(with: values)
        self.servicesSection.configure(with: values)
        self.encryptionProtocolSection.configure(with: values)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension ConversationCreationController: AddParticipantsConversationCreationDelegate {

    func addParticipantsViewController(_ addParticipantsViewController: AddParticipantsViewController, didPerform action: AddParticipantsViewController.CreateAction) {
        switch action {
        case .updatedUsers(let users):
            values.participants = users

        case .create:
            // swiftlint:disable todo_requires_jira_link
            // TODO: avoid casting to `ZMUserSession` (expand `UserSession` API)
            // swiftlint:enable todo_requires_jira_link
            guard let userSession = userSession as? ZMUserSession else { return }

            addParticipantsViewController.setLoadingView(isVisible: true)
            let service = ConversationService(context: userSession.viewContext)

            let users = values.participants
                .union([userSession.selfUser])
                .materialize(in: userSession.viewContext)

            let messageProtocol: MessageProtocol = values.encryptionProtocol == .mls ? .mls : .proteus

            service.createGroupConversation(
                name: values.name,
                users: Set(users),
                allowGuests: values.allowGuests,
                allowServices: values.allowServices,
                enableReceipts: values.enableReceipts,
                messageProtocol: messageProtocol
            ) { [weak self] result in
                guard let self else {
                    assertionFailure("expect ConversationCreationController not to be <nil>")
                    return
                }

                addParticipantsViewController.setLoadingView(isVisible: false)

                switch result {
                case .success(let conversation):
                    delegate?.conversationCreationController(
                        self,
                        didCreateConversation: conversation
                    )

                case .failure(.networkError(.missingLegalholdConsent)):
                    showMissingLegalholdConsentAlert()

                case .failure(.networkError(.nonFederatingDomains(let domains))):
                    showNonFederatingDomainsAlert(domains: domains)

                case .failure(let error):
                    WireLogger.conversation.error("failed to create conversation: \(String(describing: error))")
                    showGenericErrorAlert()
                }
            }
        }
    }

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
            url: .wr_FederationLearnMore,
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

// MARK: - SimpleTextFieldDelegate

extension ConversationCreationController: WireTextFieldDelegate {
    func textFieldDidEndEditing(_ textField: WireTextField) {

    }

    func textFieldDidBeginEditing(_ textField: WireTextField) {

    }

    func textFieldReturnPressed(_ textField: WireTextField) {
        tryToProceed()
    }

    func textField(_ textField: WireTextField, valueChanged value: WireTextField.Value) {
        errorSection.clearError()
        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
        case .valid(let text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }

    }

}

extension ConversationCreationController {

    func presentEncryptionProtocolPicker(_ completion: @escaping (Feature.MLS.Config.MessageProtocol) -> Void) {
        let alertViewController = encryptionProtocolPicker { type in
            completion(type)
        }

        alertViewController.configPopover(pointToView: view)
        present(alertViewController, animated: true)
    }

    func encryptionProtocolPicker(_ completion: @escaping (Feature.MLS.Config.MessageProtocol) -> Void) -> UIAlertController {
        typealias Localizable = L10n.Localizable.Conversation.Create

        let mlsFeature = userSession.makeGetMLSFeatureUseCase().invoke()
        let proteus = mlsFeature.config.defaultProtocol == .proteus ? Localizable.ProtocolSelection.proteusDefault : Localizable.ProtocolSelection.proteus
        let mls = mlsFeature.config.defaultProtocol == .mls ? Localizable.ProtocolSelection.mlsDefault : Localizable.ProtocolSelection.mls

        let alert = UIAlertController(
            title: Localizable.Mls.pickerTitle,
            message: nil,
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(
            title: proteus,
            style: .default,
            handler: { _ in
                completion(.proteus)
            }
        ))
        alert.addAction(UIAlertAction(
            title: mls,
            style: .default,
            handler: { _ in
                completion(.mls)
            }
        ))
        alert.addAction(UIAlertAction(
            title: Localizable.Mls.cancel,
            style: .cancel
        ))
        alert.popoverPresentationController?.permittedArrowDirections = [
            .up,
            .down
        ]

        return alert
    }
}
