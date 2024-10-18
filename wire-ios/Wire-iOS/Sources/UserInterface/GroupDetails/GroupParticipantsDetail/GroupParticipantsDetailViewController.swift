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
import WireMainNavigationUI
import WireSyncEngine

final class GroupParticipantsDetailViewController: UIViewController {

    private let mainCoordinator: AnyMainCoordinator<MainCoordinatorDependencies>
    private let collectionView = UICollectionView(forGroupedSections: ())
    private let searchViewController = SearchHeaderViewController(userSelection: .init())
    let viewModel: GroupParticipantsDetailViewModel
    private let collectionViewController: SectionCollectionViewController

    typealias PeoplePicker = L10n.Localizable.Peoplepicker

    // used for scrolling and fading selected cells
    private var firstLayout = true
    private var firstLoad = true

    weak var delegate: GroupDetailsUserDetailPresenter?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return wr_supportedInterfaceOrientations
    }

    init(
        selectedParticipants: [UserType],
        conversation: GroupParticipantsDetailConversation,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator<MainCoordinatorDependencies>
    ) {
        self.mainCoordinator = mainCoordinator

        viewModel = GroupParticipantsDetailViewModel(
            selectedParticipants: selectedParticipants,
            conversation: conversation,
            userSession: userSession
        )

        collectionViewController = SectionCollectionViewController()

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        createConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if firstLayout {
            firstLayout = false
            scrollToFirstHighlightedUser()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        firstLoad = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTitle(L10n.Localizable.Participants.All.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true)
        }, accessibilityLabel: L10n.Localizable.General.close)

        collectionViewController.collectionView?.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        })
    }

    func setupViews() {
        addToSelf(searchViewController)
        searchViewController.view.translatesAutoresizingMaskIntoConstraints = false
        searchViewController.delegate = viewModel
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        collectionViewController.collectionView = collectionView
        collectionViewController.sections = computeSections()
        viewModel.participantsDidChange = participantsDidChange

        collectionView.accessibilityIdentifier = "group_details.full_list"
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            searchViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            searchViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: searchViewController.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func participantsDidChange() {
        collectionViewController.sections = computeSections()
        collectionViewController.collectionView?.reloadData()

        let emptyResultMessage = (viewModel.admins.isEmpty && viewModel.members.isEmpty) ? PeoplePicker.noSearchResults : ""
        collectionViewController.collectionView?.setEmptyMessage(emptyResultMessage)
    }

    private func scrollToFirstHighlightedUser() {
        if let indexPath = viewModel.indexPathOfFirstSelectedParticipant {
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }

    private func computeSections() -> [CollectionViewSectionController] {
        var sections = [CollectionViewSectionController]()

        if !viewModel.admins.isEmpty {
            sections.append(
                ParticipantsSectionController(
                    participants: viewModel.admins,
                    userStatuses: viewModel.userStatuses,
                    conversationRole: .admin,
                    conversation: viewModel.conversation,
                    delegate: self,
                    totalParticipantsCount: viewModel.admins.count,
                    clipSection: false,
                    showSectionCount: false,
                    userSession: viewModel.userSession
                )
            )
        }

        if !viewModel.members.isEmpty {
            sections.append(
                ParticipantsSectionController(
                    participants: viewModel.members,
                    userStatuses: viewModel.userStatuses,
                    conversationRole: .member,
                    conversation: viewModel.conversation,
                    delegate: self,
                    totalParticipantsCount: viewModel.members.count,
                    clipSection: false,
                    showSectionCount: false,
                    userSession: viewModel.userSession
                )
            )
        }

        return sections
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return viewModel.participants[indexPath.row].isSelfUser == false
    }
}

extension GroupParticipantsDetailViewController: GroupDetailsSectionControllerDelegate {

    func presentDetails(for user: UserType) {
        guard let conversation = viewModel.conversation as? ZMConversation else { return }

        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            viewControllerDismisser: self,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator
        )
        if !user.isSelfUser {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func presentFullParticipantsList(for users: [UserType], in conversation: GroupDetailsConversationType) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }

    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {

        let detailsViewController = GroupParticipantsDetailViewController(
            selectedParticipants: selectedUsers,
            conversation: viewModel.conversation,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }

}

extension GroupParticipantsDetailViewController: ViewControllerDismisser {

    func dismiss(viewController: UIViewController, completion: (() -> Void)?) {
        navigationController?.popViewController(animated: true, completion: completion)
    }
}

extension GroupParticipantsDetailViewController: ProfileViewControllerDelegate {

    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        Task {
            await mainCoordinator.showConversationList(conversationFilter: .none)
            await mainCoordinator.showConversation(conversation: conversation, message: nil)
        }
    }
}
