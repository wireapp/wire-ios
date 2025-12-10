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
import WireDataModel
import WireDesign
import WireMessagingDomain
import WireMainNavigationUI
import WireSyncEngine

final class GroupParticipantsDetailViewController: UIViewController {

    // MARK: - Types

    typealias PeoplePicker = L10n.Localizable.Peoplepicker

    // MARK: - Properties

    private let mainCoordinator: AnyMainCoordinator
    private let selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    private let conversationCreationRepository: any ConversationCreationRepositoryProtocol
    let viewModel: GroupParticipantsDetailViewModel
    private let collectionViewController: SectionCollectionViewController

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchBar.placeholder = L10n.Localizable.Peoplepicker.searchPlaceholder
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.delegate = self
        controller.searchResultsUpdater = self
        return controller
    }()

    private lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(forGroupedSections: ())
        collection.accessibilityIdentifier = "group_details.full_list"
        collection.contentInset = .zero
        collection.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    // State tracking
    private var isFirstLayout = true

    weak var delegate: GroupDetailsUserDetailPresenter?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        wr_supportedInterfaceOrientations
    }

    // MARK: - Initialization

    init(
        selectedParticipants: [UserType],
        conversation: GroupParticipantsDetailConversation,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol,
        conversationCreationRepository: any ConversationCreationRepositoryProtocol
    ) {
        self.mainCoordinator = mainCoordinator
        self.selfProfileUIBuilder = selfProfileUIBuilder
        self.conversationCreationRepository = conversationCreationRepository

        self.viewModel = GroupParticipantsDetailViewModel(
            selectedParticipants: selectedParticipants,
            conversation: conversation,
            userSession: userSession
        )

        self.collectionViewController = SectionCollectionViewController()

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        configureViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstLayout {
            isFirstLayout = false
            scrollToFirstHighlightedUser()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureNavigationBar()
        collectionViewController.collectionView?.reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { [weak self] _ in
            self?.collectionViewController.collectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - Setup

    func setupViews() {
        view.backgroundColor = ColorTheme.Backgrounds.background

        // Setup search controller
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        view.addSubview(collectionView)
        collectionViewController.collectionView = collectionView
        collectionViewController.sections = computeSections()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureViewModel() {
        viewModel.participantsDidChange = { [weak self] in
            self?.handleParticipantsChange()
        }
    }

    private func configureNavigationBar() {
        setupNavigationBarTitle(L10n.Localizable.Participants.All.title)
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(
            action: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            },
            accessibilityLabel: L10n.Localizable.General.close
        )
    }

    // MARK: - Private Methods

    func handleParticipantsChange() {
        collectionViewController.sections = computeSections()
        collectionViewController.collectionView?.reloadData()

        let emptyResultMessage = (viewModel.admins.isEmpty && viewModel.members.isEmpty) ? PeoplePicker
            .noSearchResults : ""
        collectionViewController.collectionView?.setEmptyMessage(emptyResultMessage)
    }

    private func scrollToFirstHighlightedUser() {
        guard let indexPath = viewModel.indexPathOfFirstSelectedParticipant else { return }
        collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
    }

    private func computeSections() -> [CollectionViewSectionController] {
        var sections = [CollectionViewSectionController]()

        if !viewModel.admins.isEmpty {
            sections.append(createParticipantsSection(
                participants: viewModel.admins,
                role: .admin,
                count: viewModel.admins.count
            ))
        }

        if !viewModel.members.isEmpty {
            sections.append(createParticipantsSection(
                participants: viewModel.members,
                role: .member,
                count: viewModel.members.count
            ))
        }

        return sections
    }

    private func createParticipantsSection(
        participants: [UserType],
        role: ConversationRole,
        count: Int
    ) -> ParticipantsSectionController {
        ParticipantsSectionController(
            participants: participants,
            userStatuses: viewModel.userStatuses,
            conversationRole: role,
            conversation: viewModel.conversation,
            delegate: self,
            totalParticipantsCount: count,
            clipSection: false,
            showSectionCount: false,
            userSession: viewModel.userSession
        )
    }
}

// MARK: - UISearchResultsUpdating

extension GroupParticipantsDetailViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.updateSearch(query: searchText)
    }
}

// MARK: - UISearchBarDelegate

extension GroupParticipantsDetailViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.updateSearch(query: "")
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - GroupDetailsSectionControllerDelegate

extension GroupParticipantsDetailViewController: GroupDetailsSectionControllerDelegate {
    func presentDetails(for user: UserType) {
        guard
            !user.isSelfUser,
            let conversation = viewModel.conversation as? ZMConversation
        else { return }

        let viewController = UserDetailViewControllerFactory.createUserDetailViewController(
            user: user,
            conversation: conversation,
            profileViewControllerDelegate: self,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )

        navigationController?.pushViewController(viewController, animated: true)
    }

    func presentFullParticipantsList(for users: [UserType], in conversation: GroupDetailsConversationType) {
        presentParticipantsDetails(with: users, selectedUsers: [], animated: true)
    }

    func presentParticipantsDetails(with users: [UserType], selectedUsers: [UserType], animated: Bool) {
        let detailsViewController = GroupParticipantsDetailViewController(
            selectedParticipants: selectedUsers,
            conversation: viewModel.conversation,
            userSession: viewModel.userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )

        detailsViewController.delegate = self
        navigationController?.pushViewController(detailsViewController, animated: animated)
    }
}

// MARK: - ProfileViewControllerDelegate

extension GroupParticipantsDetailViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        Task {
            await mainCoordinator.showConversationList(conversationFilter: .none)
            await mainCoordinator.showConversation(conversation: conversation, message: nil)
        }
    }
}
