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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireDomain
import WireLogging
import WireNetwork
import WireSyncEngine

protocol ConversationCreationControllerDelegate: AnyObject {

    @MainActor
    func conversationCreationController(
        _ controller: ConversationCreationController,
        didCreateConversation conversation: ZMConversation
    )

    @MainActor
    func conversationCreationController(
        _ controller: WireConversationChannelCreationFormViewController,
        didCreateConversation conversation: ZMConversation
    )
}

final class ConversationCreationController: UIViewController {

    // MARK: - Properties

    typealias CreateGroupName = L10n.Localizable.Conversation.Create.GroupName

    private let userSession: UserSession

    private let collectionViewController = SectionCollectionViewController()

    private var preSelectedParticipants: UserSet?
    private var values: ConversationCreationValues

    weak var delegate: ConversationCreationControllerDelegate?

    // MARK: - Sections

    private lazy var nameSection = ConversationCreateNameSectionController(
        selfUser: userSession.selfUser,
        isChannel: values.isChannel,
        delegate: self
    )
    private lazy var errorSection = ConversationCreateErrorSectionController()

    private var optionsSections: [ConversationCreateSectionController] {
        let sections = [
            guestsSection,
            values.shouldIncludeApps ? appsSection : nil,
            // TODO: [WPB-16771] Remove conditional when read receipts supported on MLS
            values.encryptionProtocol != .mls ? receiptsSection : nil,
            shouldIncludeEncryptionProtocolSection ? encryptionProtocolSection : nil,
            userSession.isWireCellsEnabled ? fileManagementSection : nil
        ].compactMap(\.self)

        if let firstSection = sections.first {
            firstSection.headerTitle = L10n.Localizable.Conversation.Create.Options.title
        }

        return sections
    }

    private var shouldIncludeEncryptionProtocolSection: Bool {
        if DeveloperFlag.showCreateMLSGroupToggle.isOn {
            return true
        }

        if AutomationHelper.sharedHelper.allowMLSGroupCreation == true {
            return true
        }

        return userSession.isBackendMLSEnabled && userSession.selfUser.canCreateMLSGroups
    }

    private lazy var guestsSection: ConversationCreateGuestsSectionController = {
        let section = ConversationCreateGuestsSectionController(values: values)

        section.toggleAction = { [unowned self] allowGuests in
            values.allowGuests = allowGuests
            updateOptions()
        }

        return section
    }()

    private lazy var appsSection: ConversationCreateServicesSectionController = {
        let section = ConversationCreateServicesSectionController(values: values)

        section.toggleAction = { [unowned self] allowApps in
            values.allowApps = allowApps
            updateOptions()
        }
        return section
    }()

    private lazy var receiptsSection: ConversationCreateReceiptsSectionController = {
        let section = ConversationCreateReceiptsSectionController(values: values)

        section.toggleAction = { [unowned self] enableReceipts in
            values.enableReceipts = enableReceipts
            updateOptions()
        }

        return section
    }()

    private lazy var encryptionProtocolSection = {
        let section = ConversationEncryptionProtocolSectionController(values: values)

        section.tapAction = { sender in
            self.presentEncryptionProtocolPicker(sender: sender) { [weak self] encryptionProtocol in
                guard let self else { return }

                values.encryptionProtocol = encryptionProtocol
                updateOptions()

                reloadOptionsSections()
            }
        }
        return section
    }()

    private lazy var fileManagementSection = {
        let section = ConversationCreateFileManagementSectionController(values: values)

        section.toggleAction = { [unowned self] enableFileManagement in
            values.enableFileManagement = enableFileManagement
            updateOptions()
        }

        return section
    }()

    private func reloadOptionsSections() {
        guard let collectionView = collectionViewController.collectionView else { return }
        updateSections()

        // ignoring the conversation name so we don't loose the info while testing
        let excludedSectionIndex = collectionViewController.sections.startIndex
        let endIndex = collectionView.numberOfSections
        let sectionsToReload = IndexSet(integersIn: (excludedSectionIndex + 1) ..< endIndex)

        collectionView.performBatchUpdates {
            collectionView.reloadSections(sectionsToReload)
        }
    }

    // MARK: - Life cycle

    init(
        preSelectedParticipants: UserSet?,
        userSession: UserSession
    ) {
        self.preSelectedParticipants = preSelectedParticipants
        self.userSession = userSession
        self.values = ConversationCreationValues(
            isChannel: false,
            encryptionProtocol: userSession.defaultProtocol,
            selfUser: userSession.selfUser
        )

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault

        setupViews()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }

    // MARK: - Methods

    override var prefersStatusBarHidden: Bool {
        false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    private func setupViews() {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: if keyboard is open, it should scroll.
        let collectionView = UICollectionView(forGroupedSections: ())

        collectionView.contentInsetAdjustmentBehavior = .never

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        collectionViewController.collectionView = collectionView
        updateSections()
    }

    private func updateSections() {
        appsSection.isHidden = !values.shouldIncludeApps
        collectionViewController.sections = [nameSection, errorSection]

        if userSession.selfUser.isTeamMember {
            collectionViewController.sections.append(contentsOf: optionsSections)
        }
    }

    private func setupNavigationBar() {

        setupNavigationBarTitle(CreateGroupName.title)

        if navigationController?.viewControllers.count ?? 0 <= 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
                self?.presentingViewController?.dismiss(animated: true)
            }, accessibilityLabel: L10n.Localizable.General.close)
        }
        let nextButtonItem = UIBarButtonItem.createNavigationRightBarButtonItem(
            title: L10n.Localizable.General.next,
            action: UIAction { [weak self] _ in
                self?.tryToProceed()
            }
        )

        nextButtonItem.accessibilityIdentifier = "button.newgroup.next"
        nextButtonItem.tintColor = UIColor.accent()
        nextButtonItem.isEnabled = isGroupNameValid()
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

    private func tryToProceed() {
        guard let value = nameSection.value else { return }
        proceedWith(value: value)
    }

    private func isGroupNameValid() -> Bool {
        switch nameSection.value {
        case let .valid(name)? where !name.isEmpty:
            true
        default:
            false
        }
    }

    private func updateOptions() {
        guestsSection.configure(with: values)
        appsSection.configure(with: values)
        encryptionProtocolSection.configure(with: values)
        fileManagementSection.configure(with: values)
    }
}

// MARK: - AddParticipantsConversationCreationDelegate

extension ConversationCreationController: AddParticipantsConversationCreationDelegate {

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
                await createGroupConversation(
                    teamID: team,
                    session: userSession,
                    users: syncedUsers
                )

                addParticipantsViewController.setLoadingView(isVisible: false)
            }
        }
    }

    private func createGroupConversation(
        teamID: UUID?,
        session: ZMUserSession,
        users: [ZMUser]
    ) async {
        guard let groupConversationUseCase = session.createGroupConversationUseCase else {
            return
        }

        let accessMode: [WireNetwork.ConversationAccessMode] = values.allowGuests ? [.invite, .code] : []
        let accessRoles = ConversationAccessRoleV2.from(
            allowGuests: values.allowGuests,
            allowApps: values.shouldIncludeApps ? values.allowApps : false
        ).compactMap {
            $0.toNetworkModel()
        }

        let conversationMessageProtocol: WireNetwork.ConversationMessageProtocol = switch values.encryptionProtocol {
        case .mls:
            .mls
        case .proteus:
            .proteus
        case .mixed:
            .mixed
        }

        do {
            let conversation = try await groupConversationUseCase.invoke(
                teamID: teamID,
                messageProtocol: conversationMessageProtocol,
                name: values.name,
                users: Set(users),
                accessMode: Set(accessMode),
                accessRoles: Set(accessRoles),
                enableReceipts: values.enableReceipts,
                cells: userSession.isWireCellsEnabled ? values.enableFileManagement : nil,
                isMLSEnabled: session.isBackendMLSEnabled
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

        } catch let error as CreateGroupConversationUseCase.Failure {

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

// MARK: - WireTextFieldDelegate

extension ConversationCreationController: WireTextFieldDelegate {
    func textFieldDidEndEditing(_ textField: WireTextField) {}

    func textFieldDidBeginEditing(_ textField: WireTextField) {}

    func textFieldReturnPressed(_ textField: WireTextField) {
        tryToProceed()
    }

    func textField(_ textField: WireTextField, valueChanged value: WireTextField.Value) {
        errorSection.clearError()
        switch value {
        case .error: navigationItem.rightBarButtonItem?.isEnabled = false
        case let .valid(text): navigationItem.rightBarButtonItem?.isEnabled = !text.isEmpty
        }

    }

}

extension ConversationCreationController {

    func presentEncryptionProtocolPicker(
        sender: UIView,
        _ completion: @escaping (WireDataModel.MessageProtocol) -> Void
    ) {
        let alertController = encryptionProtocolPicker { type in
            completion(type)
        }

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sender.superview!
            popoverPresentationController.sourceRect = sender.frame.insetBy(dx: -4, dy: -4)
        }
        present(alertController, animated: true)
    }

    func encryptionProtocolPicker(_ completion: @escaping (WireDataModel.MessageProtocol) -> Void)
        -> UIAlertController {
        typealias Localizable = L10n.Localizable.Conversation.Create

        let proteus = userSession.defaultProtocol == .proteus ? Localizable.ProtocolSelection
            .proteusDefault : Localizable.ProtocolSelection.proteus
        let mls = userSession.defaultProtocol == .mls ? Localizable.ProtocolSelection.mlsDefault : Localizable
            .ProtocolSelection.mls

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

extension ConversationAccessRoleV2 {
    func toNetworkModel() -> WireNetwork.ConversationAccessRole {
        switch self {
        case .teamMember:
            .teamMember
        case .nonTeamMember:
            .nonTeamMember
        case .guest:
            .guest
        case .app:
            .app
        }
    }
}
