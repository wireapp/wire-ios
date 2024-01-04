//
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

import UIKit
import WireSyncEngine

final class GroupDetailsViewController: UIViewController, ZMConversationObserver, GroupDetailsFooterViewDelegate {

    private let collectionViewController: SectionCollectionViewController
    private let conversation: GroupDetailsConversationType
    private let footerView = GroupDetailsFooterView()
    private var token: NSObjectProtocol?
    var actionController: ConversationActionController?
    private var renameGroupSectionController: RenameGroupSectionController?
    private var syncObserver: InitialSyncObserver!
    let userSession: UserSession

    var didCompleteInitialSync = false {
        didSet {
            collectionViewController.sections = computeVisibleSections()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    init(conversation: GroupDetailsConversationType, userSession: UserSession) {
        self.conversation = conversation
        collectionViewController = SectionCollectionViewController()
        self.userSession = userSession
        super.init(nibName: nil, bundle: nil)

        createSubviews()

        if let conversation = conversation as? ZMConversation {
            userSession.perform {
                conversation.refetchParticipantsIfNeeded()
            }

            token = ConversationChangeInfo.add(observer: self, for: conversation)
            if let session = ZMUserSession.shared() {
                syncObserver = InitialSyncObserver(in: session) { [weak self] completed in
                    self?.didCompleteInitialSync = completed
                }
            }
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createSubviews() {
        let collectionView = UICollectionView(forGroupedSections: ())
        collectionView.accessibilityIdentifier = "group_details.list"

        collectionView.contentInsetAdjustmentBehavior = .never

        [collectionView, footerView].forEach(view.addSubview)

        [collectionView, footerView].prepareForLayout()
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: footerView.topAnchor),
            footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        collectionViewController.collectionView = collectionView
        footerView.delegate = self
        footerView.update(for: conversation)

        collectionViewController.sections = computeVisibleSections()

    }

    private func setupNavigatiomItem() {
        navigationItem.titleView = TwoLineTitleView(
            first: L10n.Localizable.Participants.title.capitalized.attributedString,
            second: verificationStatus)
        navigationItem.rightBarButtonItem = navigationController?.closeItem()
        navigationItem.rightBarButtonItem?.accessibilityLabel = L10n.Accessibility.ConversationDetails.CloseButton.description
        navigationItem.backBarButtonItem?.accessibilityLabel = L10n.Accessibility.Profile.BackButton.description
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

        let renameGroupSectionController = RenameGroupSectionController(conversation: conversation, userSession: userSession)
        sections.append(renameGroupSectionController)
        self.renameGroupSectionController = renameGroupSectionController

        let (participants, serviceUsers) = (conversation.sortedOtherParticipants, conversation.sortedServiceUsers)

        if !participants.isEmpty {

            let admins = participants.filter({$0.isGroupAdmin(in: conversation)})
            let members = participants.filter({!$0.isGroupAdmin(in: conversation)})

            let maxNumberOfDisplayed = Int.ConversationParticipants.maxNumberOfDisplayed
            let maxNumberWithoutTruncation = Int.ConversationParticipants.maxNumberWithoutTruncation

            if admins.count <= maxNumberWithoutTruncation || admins.isEmpty {
                // Dispay the ShowAll button after the first section.
                if admins.count >= maxNumberOfDisplayed && (participants.count > maxNumberWithoutTruncation) {
                    let adminSection = ParticipantsSectionController(
                        participants: admins,
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
                        conversationRole: .admin,
                        conversation: conversation,
                        delegate: self,
                        totalParticipantsCount: participants.count,
                        clipSection: false,
                        userSession: userSession
                    )
                    sections.append(adminSection)
                    if members.count <= (Int.ConversationParticipants.maxNumberWithoutTruncation - admins.count) { // Don't display the ShowAll button
                        if !members.isEmpty {
                            let memberSection = ParticipantsSectionController(
                                participants: members,
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

            if conversation.teamRemoteIdentifier != nil &&
                user.canModifyReadReceiptSettings(in: conversation) {
                let receiptOptionsSectionController = ReceiptOptionsSectionController(
                    conversation: conversation,
                    syncCompleted: didCompleteInitialSync,
                    collectionView: self.collectionViewController.collectionView!,
                    presentingViewController: self
                )
                sections.append(receiptOptionsSectionController)
            }
        }

        // MARK: services sections

        if !serviceUsers.isEmpty {
            let servicesSection = ServicesSectionController(serviceUsers: serviceUsers, conversation: conversation, delegate: self)
            sections.append(servicesSection)
        }

        // Protocol details
        sections.append(MessageProtocolSectionController(
            messageProtocol: conversation.messageProtocol,
            groupID: conversation.mlsGroupID
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
        else { return }

        updateLegalHoldIndicator()
        collectionViewController.sections = computeVisibleSections()
        footerView.update(for: conversation)

        if changeInfo.participantsChanged, !conversation.isSelfAnActiveMember {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    func footerView(_ view: GroupDetailsFooterView,
                    shouldPerformAction action: GroupDetailsFooterView.Action) {
        switch action {
        case .invite:
            let addParticipantsViewController = AddParticipantsViewController(
                conversation: conversation,
                userSession: userSession
            )
            let navigationController = addParticipantsViewController.wrapInNavigationController(setBackgroundColor: true)
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
        guard let conversation = conversation as? ZMConversation else { return }

        let detailsViewController = GroupParticipantsDetailViewController(
            selectedParticipants: selectedUsers,
            conversation: conversation,
            userSession: userSession
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
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
        guard let conversation = conversation as? ZMConversation else { return }

        LegalHoldDetailsViewController.present(in: self, conversation: conversation, userSession: userSession)
    }

}

// MARK: - Conversation verification status

private extension GroupDetailsViewController {

    var verificationStatus: NSAttributedString? {
        guard conversation.isVerified else {
            return nil
        }
        return attributedString(title: verificationStatusTitle, icon: verificationStatusIcon)
    }

    var verificationStatusTitle: String {
        typealias ConversationVerificationStatus = L10n.Localizable.GroupDetails.ConversationVerificationStatus

        switch conversation.messageProtocol {
        case .proteus:
            return ConversationVerificationStatus.proteus
        case .mls:
            return ConversationVerificationStatus.e2ei
        }
    }

    var verificationStatusIcon: UIImage {
        switch conversation.messageProtocol {
        case .proteus:
            return Asset.Images.verifiedShield.image
        case .mls:
            return Asset.Images.certificateValid.image
        }
    }

    var verificationStatusColor: UIColor {
        switch conversation.messageProtocol {
        case .proteus:
            return SemanticColors.Label.textCertificateVerified
        case .mls:
            return SemanticColors.Label.textCertificateValid
        }
    }

    func attributedString(title: String, icon: UIImage) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: verificationStatusColor
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

}

extension GroupDetailsViewController: ViewControllerDismisser {
    func dismiss(viewController: UIViewController, completion: (() -> Void)?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
}

extension GroupDetailsViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            ZClientViewController.shared?.load(conversation, scrollTo: nil, focusOnView: true, animated: true)
        }
    }
}

extension GroupDetailsViewController: GroupDetailsSectionControllerDelegate, GroupOptionsSectionControllerDelegate {

    func presentDetails(for user: UserType) {
        guard let conversation = conversation as? ZMConversation else { return }

        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self, userSession: userSession
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentFullParticipantsList(for users: [UserType], in conversation: GroupDetailsConversationType) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }

    func presentGuestOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else { return }
        guard let userSession = ZMUserSession.shared() else { return }
        let menu = ConversationGuestOptionsViewController(conversation: conversation, userSession: userSession)
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentServicesOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else { return }
        guard let userSession = ZMUserSession.shared() else { return }
        let menu = ConversationServicesOptionsViewController(conversation: conversation, userSession: userSession)
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentTimeoutOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else { return }
        guard let userSession = ZMUserSession.shared() else { return }
        let menu = ConversationTimeoutOptionsViewController(conversation: conversation, userSession: userSession)
        menu.dismisser = self
        navigationController?.pushViewController(menu, animated: animated)
    }

    func presentNotificationsOptions(animated: Bool) {
        guard let conversation = conversation as? ZMConversation else { return }
        guard let userSession = ZMUserSession.shared() else { return }
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
