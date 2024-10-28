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
import WireDesign
import WireMainNavigationUI
import WireReusableUIComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "StartUIViewController")

final class StartUIViewController: UIViewController {

    // MARK: - Properties

    static let InitiallyShowsKeyboardConversationThreshold = 10

    weak var delegate: StartUIDelegate?

    let searchController = UISearchController(searchResultsController: nil)

    let groupSelector = SearchGroupSelector()

    let searchResultsViewController: SearchResultsViewController

    var addressBookHelperType: AddressBookHelperProtocol.Type

    let userSession: UserSession

    let mainCoordinator: AnyMainCoordinator
    let createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol

    let isFederationEnabled: Bool

    let quickActionsBar = StartUIInviteActionBar()

    let profilePresenter: ProfilePresenter
    private var emptyResultView: EmptySearchResultsView!

    private(set) var activityIndicator: BlockingActivityIndicator!

    let backgroundColor = SemanticColors.View.backgroundDefault

    var searchResults: SearchResultsViewController {
        return self.searchResultsViewController
    }

    var showsGroupSelector: Bool {
        return SearchGroup.all.count > 1 && userSession.selfUser.canSeeServices
    }

    // MARK: - Init

    private var navigationBarTitle: String? {
        if let title = userSession.selfUser.membership?.team?.name {
            return title
        } else if let title = userSession.selfUser.name {
            return title
        }

        return nil
    }

    /// init method for injecting mock addressBookHelper
    ///
    /// - Parameter addressBookHelperType: a class type conforms AddressBookHelperProtocol
    init(
        addressBookHelperType: AddressBookHelperProtocol.Type = AddressBookHelper.self,
        isFederationEnabled: Bool = BackendInfo.isFederationEnabled,
        userSession: UserSession,
        mainCoordinator: AnyMainCoordinator,
        createGroupConversationUIBuilder: CreateGroupConversationViewControllerBuilderProtocol,
        selfProfileUIBuilder: SelfProfileViewControllerBuilderProtocol
    ) {
        self.isFederationEnabled = isFederationEnabled
        self.addressBookHelperType = addressBookHelperType
        self.searchResultsViewController = SearchResultsViewController(
            userSelection: UserSelection(),
            userSession: userSession,
            isAddingParticipants: false,
            shouldIncludeGuests: true,
            isFederationEnabled: isFederationEnabled
        )
        self.userSession = userSession
        self.mainCoordinator = mainCoordinator
        self.createGroupConversationUIBuilder = createGroupConversationUIBuilder
        profilePresenter = .init(
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder
        )
        super.init(nibName: nil, bundle: nil)

        configGroupSelector()
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = SemanticColors.View.backgroundDefault
        activityIndicator = .init(view: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = navigationBarTitle {
            setupNavigationBarTitle(title)
        }

        setupNavigationBarButtonItems()
    }

    override func accessibilityPerformEscape() -> Bool {
        _ = self.searchController.searchBar.resignFirstResponder()
        self.navigationController?.dismiss(animated: true)
        return true
    }

    // MARK: - Setup and configure views

    func setupViews() {
        configGroupSelector()
        emptyResultView = EmptySearchResultsView(
            isSelfUserAdmin: userSession.selfUser.canManageTeam,
            isFederationEnabled: isFederationEnabled
        )

        emptyResultView.delegate = self

        searchResultsViewController.mode = .list
        searchResultsViewController.searchResultsView.emptyResultView = emptyResultView
        searchResultsViewController.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        setupSearchController()

        if showsGroupSelector {
            view.addSubview(groupSelector)
        }

        searchResults.delegate = self
        addToSelf(searchResults)
        searchResults.searchResultsView.emptyResultView = emptyResultView
        searchResults.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        quickActionsBar.inviteButton.addTarget(self, action: #selector(inviteMoreButtonTapped(_:)), for: .touchUpInside)

        // view.backgroundColor = UIColor.clear

        createConstraints()
        updateActionBar()
        searchResults.searchContactList()

        view.accessibilityViewIsModal = true
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = L10n.Localizable.Peoplepicker.searchPlaceholder
        searchController.searchBar.accessibilityIdentifier = "textViewSearch"
        navigationItem.searchController = searchController
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configGroupSelector() {
        groupSelector.translatesAutoresizingMaskIntoConstraints = false
        groupSelector.backgroundColor = backgroundColor
        groupSelector.onGroupSelected = { [weak self] group in
            if .services == group {
                self?.searchController.searchBar.text = ""
            }
            self?.searchResults.searchGroup = group
            self?.performSearch()
        }
    }

    // MARK: - Setup constraints

    private func createConstraints() {
        [groupSelector, searchResultsViewController.view].forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        if showsGroupSelector {
            NSLayoutConstraint.activate([
                groupSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                groupSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                groupSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                searchResultsViewController.view.topAnchor.constraint(equalTo: groupSelector.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                searchResultsViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            searchResultsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func showKeyboardIfNeeded() {
        let conversationCount = userSession.conversationList().items.count
        if conversationCount > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            searchController.searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Instance methods

    @objc
    func performSearch() {
        let searchString = searchController.searchBar.text ?? ""
        zmLog.info("Search for \(searchString)")

        if groupSelector.group == .people {
            if searchString.isEmpty {
                searchResults.mode = .list
                searchResults.searchContactList()
            } else {
                searchResults.mode = .search
                searchResults.searchForUsers(withQuery: searchString)
            }
        } else {
            searchResults.searchForServices(withQuery: searchString)
        }
        emptyResultView.updateStatus(searchingForServices: groupSelector.group == .services,
                                     hasFilter: !searchString.isEmpty)
    }

    // MARK: - Action bar

    @objc
    func inviteMoreButtonTapped(_ sender: UIButton?) {
        if needsAddressBookPermission {
            presentShareContactsViewController()
        } else {
            navigationController?.pushViewController(ContactsViewController(), animated: true)
        }
    }

    func updateActionBar() {
        if !(searchController.searchBar.text?.isEmpty ?? true) || userSession.selfUser.hasTeam {
            searchResults.searchResultsView.accessoryView = nil
        } else {
            searchResults.searchResultsView.accessoryView = quickActionsBar
        }

        view.setNeedsLayout()
    }

}

// MARK: - UISearchResultsUpdating, UISearchBarDelegate

extension StartUIViewController: UISearchResultsUpdating, UISearchBarDelegate {

    func updateSearchResults(for searchController: UISearchController) {

        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(performSearch),
            object: nil
        )

        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        performSearch()
    }
}
