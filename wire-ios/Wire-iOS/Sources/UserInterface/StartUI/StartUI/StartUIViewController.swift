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
import WireReusableUIComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "StartUIViewController")

final class StartUIViewController: UIViewController {
    static let InitiallyShowsKeyboardConversationThreshold = 10

    weak var delegate: StartUIDelegate?

    let searchHeaderViewController = SearchHeaderViewController(userSelection: UserSelection())

    let groupSelector = SearchGroupSelector()

    let searchResultsViewController: SearchResultsViewController

    var addressBookHelperType: AddressBookHelperProtocol.Type

    let userSession: UserSession

    let isFederationEnabled: Bool

    let quickActionsBar = StartUIInviteActionBar()

    let profilePresenter: ProfilePresenter
    private var emptyResultView: EmptySearchResultsView!

    private(set) var activityIndicator: BlockingActivityIndicator!

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    let backgroundColor = SemanticColors.View.backgroundDefault

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
        mainCoordinator: MainCoordinating
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
        self.profilePresenter = .init(mainCoordinator: mainCoordinator)
        super.init(nibName: nil, bundle: nil)

        configGroupSelector()
        setupViews()
    }

    var searchHeader: SearchHeaderViewController {
        searchHeaderViewController
    }

    var searchResults: SearchResultsViewController {
        searchResultsViewController
    }

    // MARK: - Life cycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator = .init(view: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let title = navigationBarTitle {
            setupNavigationBarTitle(title)
        }

        navigationController?.navigationBar.barTintColor = backgroundColor
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.onDismissPressed()
        }, accessibilityLabel: L10n.Accessibility.ContactsList.CloseButton.description)
    }

    private func configGroupSelector() {
        groupSelector.translatesAutoresizingMaskIntoConstraints = false
        groupSelector.backgroundColor = backgroundColor
    }

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

        searchHeader.delegate = self
        searchHeader.allowsMultipleSelection = false
        searchHeader.view.backgroundColor = backgroundColor

        addToSelf(searchHeader)

        groupSelector.onGroupSelected = { [weak self] group in
            if group == .services {
                // Remove selected users when switching to services tab to avoid the user confusion: users in the field
                // are
                // not going to be added to the new conversation with the bot.
                self?.searchHeader.clearInput()
            }

            self?.searchResults.searchGroup = group
            self?.performSearch()
        }

        if showsGroupSelector {
            view.addSubview(groupSelector)
        }

        searchResults.delegate = self
        addToSelf(searchResults)
        searchResults.searchResultsView.emptyResultView = emptyResultView
        searchResults.searchResultsView.collectionView.accessibilityIdentifier = "search.list"

        quickActionsBar.inviteButton.addTarget(self, action: #selector(inviteMoreButtonTapped(_:)), for: .touchUpInside)

        view.backgroundColor = UIColor.clear

        createConstraints()
        updateActionBar()
        searchResults.searchContactList()

        view.accessibilityViewIsModal = true
    }

    private func createConstraints() {
        [searchHeaderViewController.view, groupSelector, searchResultsViewController.view]
            .forEach { $0?.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            searchHeaderViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchHeaderViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchHeaderViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
        ])

        if showsGroupSelector {
            NSLayoutConstraint.activate([
                groupSelector.topAnchor.constraint(equalTo: searchHeaderViewController.view.bottomAnchor),
                searchResultsViewController.view.topAnchor.constraint(equalTo: groupSelector.bottomAnchor),
            ])

            NSLayoutConstraint.activate([
                groupSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                groupSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                searchResultsViewController.view.topAnchor
                    .constraint(equalTo: searchHeaderViewController.view.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            searchResultsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    var showsGroupSelector: Bool {
        SearchGroup.all.count > 1 && userSession.selfUser.canSeeServices
    }

    func showKeyboardIfNeeded() {
        let conversationCount = userSession.conversationList().items.count
        if conversationCount > StartUIViewController.InitiallyShowsKeyboardConversationThreshold {
            _ = searchHeader.tokenField.becomeFirstResponder()
        }
    }

    func updateActionBar() {
        if !searchHeader.query.isEmpty || userSession.selfUser.hasTeam {
            searchResults.searchResultsView.accessoryView = nil
        } else {
            searchResults.searchResultsView.accessoryView = quickActionsBar
        }

        view.setNeedsLayout()
    }

    private func onDismissPressed() {
        _ = searchHeader.tokenField.resignFirstResponder()
        navigationController?.dismiss(animated: true)
    }

    override func accessibilityPerformEscape() -> Bool {
        onDismissPressed()
        return true
    }

    // MARK: - Instance methods

    @objc
    func performSearch() {
        let searchString = searchHeader.query
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
        emptyResultView.updateStatus(
            searchingForServices: groupSelector.group == .services,
            hasFilter: !searchString.isEmpty
        )
    }

    // MARK: - Action bar

    @objc
    func inviteMoreButtonTapped(_: UIButton?) {
        if needsAddressBookPermission {
            presentShareContactsViewController()
        } else {
            navigationController?.pushViewController(ContactsViewController(), animated: true)
        }
    }
}

extension StartUIViewController: SearchHeaderViewControllerDelegate {
    func searchHeaderViewController(
        _ searchHeaderViewController: SearchHeaderViewController,
        updatedSearchQuery query: String
    ) {
        searchResults.cancelPreviousSearch()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performSearch), object: nil)
        perform(#selector(performSearch), with: nil, afterDelay: 0.2)
    }

    func searchHeaderViewControllerDidConfirmAction(_ searchHeaderViewController: SearchHeaderViewController) {
        searchHeaderViewController.resetQuery()
    }
}
