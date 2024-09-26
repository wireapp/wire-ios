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
import WireDataModel
import WireDesign
import WireMainNavigation
import WireSyncEngine

final class LegalHoldDetailsViewController: UIViewController {

    private let collectionView = UICollectionView(forGroupedSections: ())
    private let collectionViewController: SectionCollectionViewController
    private let conversation: LegalHoldDetailsConversation
    let userSession: UserSession
    private let mainCoordinator: MainCoordinatorProtocol

    convenience init?(
        user: UserType,
        userSession: UserSession,
        mainCoordinator: some MainCoordinatorProtocol
    ) {
        guard let conversation = user.oneToOneConversation else { return nil }
        self.init(
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }

    init(
        conversation: LegalHoldDetailsConversation,
        userSession: UserSession,
        mainCoordinator: some MainCoordinatorProtocol
    ) {
        self.conversation = conversation
        self.collectionViewController = SectionCollectionViewController()
        self.collectionViewController.collectionView = collectionView
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator

        super.init(nibName: nil, bundle: nil)

        setupViews()
        createConstraints()
        collectionViewController.sections = computeVisibleSections()
        collectionView.accessibilityIdentifier = "list.legalhold"
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @discardableResult
    static func present(
        in parentViewController: UIViewController,
        user: UserType,
        userSession: UserSession,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UINavigationController? {
        guard let legalHoldDetailsViewController = LegalHoldDetailsViewController(user: user, userSession: userSession, mainCoordinator: mainCoordinator) else { return nil }

        return legalHoldDetailsViewController.wrapInNavigationControllerAndPresent(from: parentViewController)
    }

    @discardableResult
    static func present(
        in parentViewController: UIViewController,
        conversation: ZMConversation,
        userSession: UserSession,
        mainCoordinator: some MainCoordinatorProtocol
    ) -> UINavigationController {
        let legalHoldDetailsViewController = LegalHoldDetailsViewController(conversation: conversation, userSession: userSession, mainCoordinator: mainCoordinator)

        return legalHoldDetailsViewController.wrapInNavigationControllerAndPresent(from: parentViewController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(L10n.Localizable.Legalhold.Header.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        (conversation as? ZMConversation)?.verifyLegalHoldSubjects()
    }

    private func setupViews() {

        view.addSubview(collectionView)

        collectionView.contentInsetAdjustmentBehavior = .never
    }

    private func createConstraints() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func computeVisibleSections() -> [CollectionViewSectionController] {
        let headerSection = SingleViewSectionController(view: LegalHoldHeaderView(frame: .zero))
        let legalHoldParticipantsSection = LegalHoldParticipantsSectionController(conversation: conversation)
        legalHoldParticipantsSection.delegate = self

        return [headerSection, legalHoldParticipantsSection]
    }

}

extension LegalHoldDetailsViewController: LegalHoldParticipantsSectionControllerDelegate {

    func legalHoldParticipantsSectionWantsToPresentUserProfile(for user: UserType) {
        guard let viewer = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        let profileViewController = ProfileViewController(
            user: user,
            viewer: viewer,
            context: .deviceList,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
        show(profileViewController, sender: nil)
    }
}
