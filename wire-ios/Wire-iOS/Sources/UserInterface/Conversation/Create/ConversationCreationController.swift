////
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireCommonComponents
import WireDataModel
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

    private let selfUser: UserType
    static let mainViewHeight: CGFloat = 56

    private let collectionViewController = SectionCollectionViewController()

    fileprivate var navBarBackgroundView = UIView()

    private var preSelectedParticipants: UserSet?
    private var values: ConversationCreationValues

    weak var delegate: ConversationCreationControllerDelegate?

    // MARK: - Sections

    private lazy var nameSection = ConversationCreateNameSectionController(selfUser: selfUser, delegate: self)
    private lazy var errorSection = ConversationCreateErrorSectionController()

    private lazy var optionsToggle: ConversationCreateOptionsSectionController = {
        let section = ConversationCreateOptionsSectionController(values: values)
        section.tapHandler = optionsTapped
        return section
    }()

    private lazy var optionsSections = [
        guestsSection,
        servicesSection,
        receiptsSection,
        shouldIncludeEncryptionProtocolSection ? encryptionProtocolSection : nil
    ].compactMap(\.self)

    private var shouldIncludeEncryptionProtocolSection: Bool {
        if DeveloperFlag.showCreateMLSGroupToggle.isOn {
            return true
        }

        if AutomationHelper.sharedHelper.allowMLSGroupCreation == true {
            return true
        }

        return selfUser.canCreateMLSGroups
    }

    private lazy var guestsSection: ConversationCreateGuestsSectionController = {
        let section = ConversationCreateGuestsSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] allowGuests in
            self.values.allowGuests = allowGuests
            self.updateOptions()
        }

        return section
    }()

    private lazy var servicesSection: ConversationCreateServicesSectionController = {
        let section = ConversationCreateServicesSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] allowServices in
            self.values.allowServices = allowServices
            self.updateOptions()
        }
        return section
    }()

    private lazy var receiptsSection: ConversationCreateReceiptsSectionController = {
        let section = ConversationCreateReceiptsSectionController(values: values)
        section.isHidden = true

        section.toggleAction = { [unowned self] enableReceipts in
            self.values.enableReceipts = enableReceipts
            self.updateOptions()
        }

        return section
    }()

    private lazy var encryptionProtocolSection: ConversationEncryptionProtocolSectionController = {
        let section = ConversationEncryptionProtocolSectionController(values: values)
        section.isHidden = true

        section.tapAction = {
            self.presentEncryptionProtocolPicker { [weak self] encryptionProtocol in
                self?.values.encryptionProtocol = encryptionProtocol
                self?.updateOptions()
            }
        }

        return section
    }()

    // MARK: - Life cycle

    init(preSelectedParticipants: UserSet?, selfUser: UserType) {
        self.selfUser = selfUser
        self.values = ConversationCreationValues(selfUser: selfUser)
        self.preSelectedParticipants = preSelectedParticipants
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        navigationItem.setupNavigationBarTitle(title: CreateGroupName.title.capitalized)

        setupNavigationBar()
        setupViews()

        // try to overtake the first responder from the other view
        if UIResponder.currentFirst != nil {
            nameSection.becomeFirstResponder()
        }
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
        // TODO: if keyboard is open, it should scroll.
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

        if selfUser.isTeamMember {
            collectionViewController.sections.append(contentsOf: [optionsToggle] + optionsSections)
        }

        navBarBackgroundView.backgroundColor = SemanticColors.View.backgroundDefault
        view.addSubview(navBarBackgroundView)

        navBarBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            navBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeTopAnchor)
        ])
    }

    private func setupNavigationBar() {
        self.navigationController?.navigationBar.tintColor = SemanticColors.Label.textDefault
        self.navigationController?.navigationBar.titleTextAttributes = DefaultNavigationBar.titleTextAttributes(for: SemanticColors.Label.textDefault)

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

    func proceedWith(value: SimpleTextField.Value) {
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

            guard let session = ZMUserSession.shared() else { return }

            let participantsController = AddParticipantsViewController(
                context: .create(values),
                selfUser: selfUser,
                userSession: session
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
        self.optionsToggle.configure(with: values)
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
            guard let userSession = ZMUserSession.shared() else { return }

            addParticipantsViewController.setLoadingView(isVisible: true)
            let service = ConversationService(context: userSession.viewContext)

            let users = values.participants
                .union([selfUser])
                .materialize(in: userSession.viewContext)

            service.createGroupConversation(
                name: values.name,
                users: Set(users),
                allowGuests: values.allowGuests,
                allowServices: values.allowServices,
                enableReceipts: values.enableReceipts,
                messageProtocol: values.encryptionProtocol == .proteus ? .proteus : .mls
            ) { [weak self] in
                guard let self = self else { return }

                addParticipantsViewController.setLoadingView(isVisible: false)

                switch $0 {
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
            alertAction: .ok(style: .cancel)
        )

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
            alertAction: .ok(style: .cancel)
        )

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

extension ConversationCreationController: SimpleTextFieldDelegate {

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {
        errorSection.clearError()
        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
        case .valid(let text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }

    }

    func textFieldReturnPressed(_ textField: SimpleTextField) {
        tryToProceed()
    }

    func textFieldDidBeginEditing(_ textField: SimpleTextField) {

    }

    func textFieldDidEndEditing(_ textField: SimpleTextField) {

    }
}

// MARK: - Handlers

extension ConversationCreationController {

    private func optionsTapped(expanded: Bool) {
        guard let collectionView = collectionViewController.collectionView else {
            return
        }

        let changes: () -> Void
        let indexSet = IndexSet(integersIn: 3..<(3+optionsSections.count))

        if expanded {
            nameSection.resignFirstResponder()
            expandOptions()
            changes = { collectionView.insertSections(indexSet) }
        } else {
            collapseOptions()
            changes = { collectionView.deleteSections(indexSet) }
        }

        collectionView.performBatchUpdates(changes)
    }

    func expandOptions() {
        optionsSections.forEach {
            $0.isHidden = false
        }
    }

    func collapseOptions() {
        optionsSections.forEach {
            $0.isHidden = true
        }
    }

}

extension ConversationCreationController {

    func presentEncryptionProtocolPicker(_ completion: @escaping (EncryptionProtocol) -> Void) {
        let alertViewController = encryptionProtocolPicker { type in
            completion(type)
        }

        alertViewController.configPopover(pointToView: view)
        present(alertViewController, animated: true)
    }

    func encryptionProtocolPicker(_ completion: @escaping (EncryptionProtocol) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: L10n.Localizable.Conversation.Create.Mls.pickerTitle, message: nil, preferredStyle: .actionSheet)

        for encryptionProtocol in EncryptionProtocol.allCases {
            alert.addAction(UIAlertAction(title: encryptionProtocol.rawValue, style: .default, handler: { _ in
                completion(encryptionProtocol)
            }))
        }

        alert.popoverPresentationController?.permittedArrowDirections = [ .up, .down ]
        alert.addAction(UIAlertAction(title: L10n.Localizable.Conversation.Create.Mls.cancel, style: .cancel, handler: nil))

        return alert
    }
}

enum EncryptionProtocol: String, CaseIterable {
    case proteus = "Proteus (default)"
    case mls = "MLS"
}
