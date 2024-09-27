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

// MARK: - GroupDetailsViewController

final class GroupDetailsViewController: UIViewController, ZMConversationObserver, GroupDetailsFooterViewDelegate {
    // MARK: Lifecycle

    init(
        conversation: GroupDetailsConversationType,
        userSession: UserSession,
        mainCoordinator: MainCoordinating,
        isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol
    ) {
        self.conversation = conversation
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.isUserE2EICertifiedUseCase = isUserE2EICertifiedUseCase
        self.collectionViewController = SectionCollectionViewController()
        super.init(nibName: nil, bundle: nil)

        createSubviews()

        if let conversation = conversation as? ZMConversation {
            userSession.perform {
                conversation.refetchParticipantsIfNeeded()
            }

            self.token = ConversationChangeInfo.add(observer: self, for: conversation)

            if let session = ZMUserSession.shared() {
                if session.hasCompletedInitialSync {
                    self.didCompleteInitialSync = true
                } else {
                    self.initialSyncToken = NotificationInContext.addObserver(
                        name: .initialSync,
                        context: userSession.notificationContext
                    ) { [weak self] _ in
                        session.managedObjectContext.performGroupedBlock {
                            self?.didCompleteInitialSync = true
                            self?.initialSyncToken = nil
                        }
                    }
                }
            }
        }

        updateUserE2EICertificationStatuses()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    var actionController: ConversationActionController?
    let userSession: UserSession

    var didCompleteInitialSync = false {
        didSet { collectionViewController.sections = computeVisibleSections() }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateLegalHoldIndicator()
        setupNavigatiomItem()
        collectionViewController.collectionView?.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupNavigatiomItem()
    }

    func updateLegalHoldIndicator() {
        navigationItem.leftBarButtonItem = conversation.isUnderLegalHold ? legalholdItem : nil
    }

    func computeVisibleSections() -> [CollectionViewSectionController] {
        var sections = [CollectionViewSectionController]()

        let renameGroupSectionController = RenameGroupSectionController(
            conversation: conversation,
            userSession: userSession
        )
        sections.append(renameGroupSectionController)
        self.renameGroupSectionController = renameGroupSectionController

        let (participants, serviceUsers) = (conversation.sortedOtherParticipants, conversation.sortedServiceUsers)
        for user in participants {
            if !userStatuses.keys.contains(user.remoteIdentifier) {
                userStatuses[user.remoteIdentifier] = .init(user: user, isE2EICertified: false)
            }
        }

        if !participants.isEmpty {
            let admins = participants.filter { $0.isGroupAdmin(in: conversation) }
            let members = participants.filter { !$0.isGroupAdmin(in: conversation) }

            let maxNumberOfDisplayed = Int.ConversationParticipants.maxNumberOfDisplayed
            let maxNumberWithoutTruncation = Int.ConversationParticipants.maxNumberWithoutTruncation

            if admins.count <= maxNumberWithoutTruncation || admins.isEmpty {
                // Dispay the ShowAll button after the first section.
                if admins.count >= maxNumberOfDisplayed, participants.count > maxNumberWithoutTruncation {
                    let adminSection = ParticipantsSectionController(
                        participants: admins,
                        userStatuses: userStatuses,
                        conversationRole: .admin,
                        conversation: conversation,
                        delegate: self,
                        totalParticipantsCount: participants.count,
                        clipSection: true,
                        maxParticipants: admins.count - 1,
                        maxDisplayedParticipants: Int.ConversationParticipants.maxNumberOfDisplayed,
                        userSession: userSession
                    )
                    sections.append(adminSection)
                } else {
                    let adminSection = ParticipantsSectionController(
                        participants: admins,
                        userStatuses: userStatuses,
                        conversationRole: .admin,
                        conversation: conversation,
                        delegate: self,
                        totalParticipantsCount: participants.count,
                        clipSection: false,
                        userSession: userSession
                    )
                    sections.append(adminSection)
                    if members
                        .count <=
                        (Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count) {
                        // Don't display the ShowAll button
                        if !members.isEmpty {
                            let memberSection = ParticipantsSectionController(
                                participants: members,
                                userStatuses: userStatuses,
                                conversationRole: .member,
                                conversation: conversation,
                                delegate: self,
                                totalParticipantsCount: participants.count,
                                clipSection: false,
                                userSession: userSession
                            )
                            sections.append(memberSection)
                        }
                    } else { // Display the ShowAll button after the second section
                        let maxParticipants = Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count
                        let memberSection = ParticipantsSectionController(
                            participants: members,
                            userStatuses: userStatuses,
                            conversationRole: .member,
                            conversation: conversation,
                            delegate: self,
                            totalParticipantsCount: participants.count,
                            clipSection: true,
                            maxParticipants: maxParticipants,
                            maxDisplayedParticipants: maxParticipants - 2,
                            userSession: userSession
                        )
                        sections.append(memberSection)
                    }
                }
            } else { // Display only one section without the ShowAll button
                let adminSection = ParticipantsSectionController(
                    participants: admins,
                    userStatuses: userStatuses,
                    conversationRole: .admin,
                    conversation: conversation,
                    delegate: self,
                    totalParticipantsCount: participants.count,
                    clipSection: true,
                    userSession: userSession
                )
                sections.append(adminSection)
            }
        }

        if let user = SelfUser.provider?.providedSelfUser {
            // MARK: options sections

            let optionsSectionController = GroupOptionsSectionController(
                conversation: conversation,
                user: user,
                delegate: self,
                syncCompleted: didCompleteInitialSync
            )
            if optionsSectionController.hasOptions {
                sections.append(optionsSectionController)
            }

            if conversation.teamRemoteIdentifier != nil,
               user.canModifyReadReceiptSettings(in: conversation) {
                let receiptOptionsSectionController = ReceiptOptionsSectionController(
                    conversation: conversation,
                    syncCompleted: didCompleteInitialSync,
                    collectionView: collectionViewController.collectionView!,
                    presentingViewController: self
                )
                sections.append(receiptOptionsSectionController)
            }
        }

        // MARK: services sections

        if !serviceUsers.isEmpty {
            let servicesSection = ServicesSectionController(
                serviceUsers: serviceUsers,
                conversation: conversation,
                delegate: self
            )
            sections.append(servicesSection)
        }

        // Protocol details
        sections.append(MessageProtocolSectionController(
            messageProtocol: conversation.messageProtocol,
            groupID: conversation.mlsGroupID,
            ciphersuite: conversation.ciphersuite
        ))

        return sections
    }

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard let conversation = conversation as? ZMConversation,
              changeInfo.participantsChanged ||
              changeInfo.nameChanged ||
              changeInfo.allowGuestsChanged ||
              changeInfo.allowServicesChanged ||
              changeInfo.destructionTimeoutChanged ||
              changeInfo.mutedMessageTypesChanged ||
              changeInfo.legalHoldStatusChanged
        else {
            return
        }

        updateLegalHoldIndicator()
        collectionViewController.sections = computeVisibleSections()
        footerView.update(for: conversation)

        if changeInfo.participantsChanged, !conversation.isSelfAnActiveMember {
            navigationController?.popToRootViewController(animated: true)
        } else {
            updateUserE2EICertificationStatuses()
        }

        if changeInfo.mlsVerificationStatusChanged {
            setupNavigatiomItem()
        }
    }

    func footerView(
        _ view: GroupDetailsFooterView,
        shouldPerformAction action: GroupDetailsFooterView.Action
    ) {
        switch action {
        case .invite:
            let addParticipantsViewController = AddParticipantsViewController(
                conversation: conversation,
                userSession: userSession
            )
            let navigationController = addParticipantsViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .currentContext

            present(navigationController, animated: true)

        case .more:
            actionController = ConversationActionController(
                conversation: conversation,
                target: self,
                sourceView: view,
                userSession: userSession
            )
            actionController?.presentMenu(from: view, context: .details)
        }
    }

    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }

        let detailsViewController = GroupParticipantsDetailViewController(
            selectedParticipants: selectedUsers,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }

    // MARK: Private

    private let mainCoordinator: MainCoordinating
    private let collectionViewController: SectionCollectionViewController
    private let conversation: GroupDetailsConversationType
    private let footerView = GroupDetailsFooterView()
    private var token: NSObjectProtocol?
    private var renameGroupSectionController: RenameGroupSectionController?
    private var initialSyncToken: (any NSObjectProtocol)!
    private var userStatuses = [UUID: UserStatus]()
    private let isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol

    private func createSubviews() {
        let collectionView = UICollectionView(forGroupedSections: ())
        collectionView.accessibilityIdentifier = "group_details.list"

        collectionView.contentInsetAdjustmentBehavior = .never

        for subview in [collectionView, footerView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        collectionViewController.collectionView = collectionView
        footerView.delegate = self
        footerView.update(for: conversation)

        collectionViewController.sections = computeVisibleSections()
    }

    private func setupNavigatiomItem() {
        navigationController?.navigationBar.backgroundColor = SemanticColors.View.backgroundDefault
        navigationItem.titleView = TwoLineTitleView(
            first: L10n.Localizable.Participants.title.capitalized.attributedString,
            second: verificationStatus
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Accessibility.ConversationDetails.CloseButton.description)

        navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.Profile.BackButton.description
    }
}

extension GroupDetailsViewController {
    private var legalholdItem: UIBarButtonItem {
        let item = UIBarButtonItem(icon: .legalholdactive, target: self, action: #selector(presentLegalHoldDetails))
        item.setLegalHoldAccessibility()
        item.tintColor = SemanticColors.Icon.foregroundDefaultRed
        return item
    }

    @objc
    func presentLegalHoldDetails() {
        guard let conversation = conversation as? ZMConversation else {
            return
        }

        LegalHoldDetailsViewController.present(
            in: self,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }
}

// MARK: - Conversation verification status

extension GroupDetailsViewController {
    private var verificationStatus: NSAttributedString? {
        guard conversation.isVerified else {
            return nil
        }
        return attributedString(title: verificationStatusTitle, icon: verificationStatusIcon)
    }

    private var verificationStatusTitle: String {
        typealias ConversationVerificationStatus = L10n.Localizable.GroupDetails.ConversationVerificationStatus

        switch conversation.messageProtocol {
        case .mixed, .proteus:
            return ConversationVerificationStatus.proteus
        case .mls:
            return ConversationVerificationStatus.e2ei
        }
    }

    private var verificationStatusIcon: UIImage {
        switch conversation.messageProtocol {
        case .mixed, .proteus:
            .init(resource: .verifiedShield)
        case .mls:
            .init(resource: .certificateValid)
        }
    }

    private var verificationStatusColor: UIColor {
        switch conversation.messageProtocol {
        case .mixed, .proteus:
            SemanticColors.Label.textCertificateVerified
        case .mls:
            SemanticColors.Label.textCertificateValid
        }
    }

    private func attributedString(title: String, icon: UIImage) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: verificationStatusColor,
        ]
        let attributedString = NSMutableAttributedString(string: title, attributes: attributes)
        let imageTextAttachment = NSTextAttachment(image: icon)

        let imageSize = CGSize(width: 12, height: 12)
        let verticalOffset: CGFloat = -2
        imageTextAttachment.bounds = CGRect(x: 0, y: verticalOffset, width: imageSize.width, height: imageSize.height)

        let imageTextAttachmentString = NSAttributedString(attachment: imageTextAttachment)
        attributedString.append(" ".attributedString)
        attributedString.append(imageTextAttachmentString)

        return attributedString
    }

    private func updateUserE2EICertificationStatuses() {
        Task { @MainActor in
            for user in conversation.sortedOtherParticipants {
                guard let user = user as? ZMUser else {
                    continue
                }
                guard let conversation = conversation as? ZMConversation else {
                    continue
                }
                do {
                    let isE2EICertified = try await isUserE2EICertifiedUseCase.invoke(
                        conversation: conversation,
                        user: user
                    )
                    userStatuses[user.remoteIdentifier]?.isE2EICertified = isE2EICertified
                } catch {
                    WireLogger.e2ei.error("Failed to get verification status for user: \(error)")
                }
            }
            collectionViewController.sections = computeVisibleSections()
        }
    }
}

// MARK: ViewControllerDismisser

extension GroupDetailsViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> Void)?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
}

// MARK: ProfileViewControllerDelegate

extension GroupDetailsViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            self.mainCoordinator.openConversation(conversation, focusOnView: true, animated: true)
        }
    }
}

// MARK: GroupDetailsSectionControllerDelegate, GroupOptionsSectionControllerDelegate

extension GroupDetailsViewController: GroupDetailsSectionControllerDelegate, GroupOptionsSectionControllerDelegate {
    func presentDetails(for user: UserType) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }

        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentFullParticipantsList(for users: [UserType], in conversation: GroupDetailsConversationType) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }

    func presentGuestOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        let menu = ConversationGuestOptionsViewController(conversation: conversation, userSession: userSession)
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentServicesOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        let menu = ConversationServicesOptionsViewController(conversation: conversation, userSession: userSession)
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentTimeoutOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        let menu = ConversationTimeoutOptionsViewController(conversation: conversation, userSession: userSession)
        menu.dismisser = self
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentNotificationsOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else {
            return
        }
        guard let userSession = ZMUserSession.shared() else {
            return
        }
        let menu = ConversationNotificationOptionsViewController(conversation: conversation, userSession: userSession)
        menu.dismisser = self
        navigationController?.pushViewController(menu, animated: animated)
    }
}

extension ZMConversation {
    func refetchParticipantsIfNeeded() {
        for user in sortedOtherParticipants where user.isPendingMetadataRefresh {
            user.refreshData()
        }
    }
}
