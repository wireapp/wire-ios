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

protocol ConversationCreationValuesConfigurable: AnyObject {
    func configure(with values: ConversationCreationValues)
}

final class ConversationCreationValues {

    private var unfilteredParticipants: UserSet
    private let selfUser: UserType

    var name: String
    var allowGuests: Bool
    var allowServices: Bool
    var enableReceipts: Bool
    var encryptionProtocol: EncryptionProtocol

    var participants: UserSet {
        get {
            var result = unfilteredParticipants

            if !allowGuests {
                let noGuests = result.filter { $0.isOnSameTeam(otherUser: selfUser) }
                result = UserSet(noGuests)
            }

            if !allowServices {
                let noServices = result.filter { !$0.isServiceUser }
                result = UserSet(noServices)
            }

            return result
        }
        set {
            unfilteredParticipants = newValue
        }
    }

    init(
        name: String = "",
        participants: UserSet = UserSet(),
        allowGuests: Bool = true,
        allowServices: Bool = true,
        enableReceipts: Bool = true,
        encryptionProtocol: EncryptionProtocol = .proteus,
        selfUser: UserType
    ) {
        self.name = name
        self.unfilteredParticipants = participants
        self.allowGuests = allowGuests
        self.allowServices = allowServices
        self.enableReceipts = enableReceipts
        self.encryptionProtocol = encryptionProtocol
        self.selfUser = selfUser
    }
}

protocol ConversationCreationControllerDelegate: AnyObject {
    func conversationCreationController(
        _ controller: ConversationCreationController,
        didCreateConversation conversation: ZMConversation
    )

    func conversationCreationController(
        _ controller: ConversationCreationController,
        didFailToCreateConversation failure: GroupConversationCreationEvent.FailureType
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
    var conversationCreationCoordinator: GroupConversationCreationCoordinator?

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

    convenience init() {
        self.init(preSelectedParticipants: nil, selfUser: ZMUser.selfUser())
    }

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

        conversationCreationCoordinator = GroupConversationCreationCoordinator()
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

            let participantsController = AddParticipantsViewController(context: .create(values))
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
            createConversation()
        }
    }

    private func createConversation() {
        guard let conversationCreationCoordinator = conversationCreationCoordinator else { return }
        var allParticipants = values.participants
        allParticipants.insert(selfUser)
        navigationController?.isLoadingViewVisible = true
        let initialized = conversationCreationCoordinator.initialize(eventHandler: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .showLoader:
                self.navigationController?.isLoadingViewVisible = true
            case .hideLoader:
                self.navigationController?.isLoadingViewVisible = false
            case .presentPopup(let popup):
                switch popup {
                case .nonFederatingBackends(let backends, let handler):
                    self.showNotFullyConnectedGraphAlert(nonFederatingBackends: backends, actionHandler: handler)
                case .missingLegalHoldConsent(let handler):
                    self.showMissingLegalConsentPopup(completionHandler: handler)
                }
            case .failure(let failure):
                self.delegate?.conversationCreationController(self, didFailToCreateConversation: failure)
            case .success(let conversation):
                self.delegate?.conversationCreationController(self, didCreateConversation: conversation)
            case .openURL(let url):
                _ = url.openAsLink()
            }
        })
        guard initialized else {
            conversationCreationCoordinator.finalize()
            return
        }
        let creatingConversation = conversationCreationCoordinator.createConversation(
            withUsers: values.participants,
            name: values.name, allowGuests: values.allowGuests,
            allowServices: values.allowServices,
            enableReceipts: values.enableReceipts,
            encryptionProtocol: values.encryptionProtocol
        )
        guard creatingConversation else {
            conversationCreationCoordinator.finalize()
            return
        }
    }

    private func showMissingLegalConsentPopup(completionHandler: @escaping () -> Void) {
        typealias ConversationError = L10n.Localizable.Error.Conversation
        UIAlertController.showErrorAlert(
            title: ConversationError.title,
            message: ConversationError.missingLegalholdConsent,
            completion: { _ in completionHandler() }
        )
    }

    private func showNotFullyConnectedGraphAlert(nonFederatingBackends: NonFederatingBackendsTuple, actionHandler: @escaping (NonFullyConnectedGraphAction) -> Void) {
        let alert = UIAlertController.notFullyConnectedGraphAlert(
            backends: nonFederatingBackends,
            completion: actionHandler
        )
        alert.presentTopmost()
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

extension UIAlertController {
    static func notFullyConnectedGraphAlert(backends: NonFederatingBackendsTuple, completion: @escaping (NonFullyConnectedGraphAction) -> Void) -> UIAlertController {
        typealias NfcgError = L10n.Localizable.Error.Conversation.Nfcg
        let alert = UIAlertController(
            title: NfcgError.title,
            message: NfcgError.messageWithBackends(backends: backends.backends),
            preferredStyle: .alert)
        let editParticipantsAction = UIAlertAction(
            title: NfcgError.edit,
            style: .default,
            handler: { _ in completion(.editParticipantsList) }
        )
        let discardGroupCreationAction = UIAlertAction(
            title: NfcgError.discard,
            style: .default,
            handler: { _ in completion(.discardGroupCreation) }
        )
        let learnMoreAction = UIAlertAction(
            title: NfcgError.learnMore,
            style: .default,
            handler: { _ in completion(.learnMore) }
        )
        alert.addAction(editParticipantsAction)
        alert.addAction(discardGroupCreationAction)
        alert.addAction(learnMoreAction)
        alert.preferredAction = editParticipantsAction
        return alert
    }
}

extension L10n.Localizable.Error.Conversation.Nfcg {
    internal static func backendsList(backends: [String]) -> String {
        typealias NfcgError = L10n.Localizable.Error.Conversation.Nfcg
        guard backends.count >= 2 else { return "" }
        var backendsString = backends[0]
        for i in 1..<backends.count-1 {
            backendsString = NfcgError.backendListDelimeter(backendsString, backends[i])
        }
        backendsString = NfcgError.backendListEnd(backendsString, backends[backends.count-1])
        return backendsString
    }

    internal static func messageWithBackends(backends: [String]) -> String {
        typealias NfcgError = L10n.Localizable.Error.Conversation.Nfcg
        return NfcgError.message(backendsList(backends: backends))
    }
}
